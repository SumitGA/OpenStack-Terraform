###############################################################################
# main.tf
# Provider configuration + the full tenant: network, subnet, router,
# security group, keypair, VM, and floating IP.
#
###############################################################################

terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.0"
    }
  }
}

provider "openstack" {
  cloud = var.cloud_name

  # We talk to the INTERNAL endpoints directly (the public FQDN only
  # tunnels the dashboard, not the API ports). These point at the VIP.
  endpoint_overrides = {
    "identity" = "http://${var.vip_address}:5000/v3/"
    "network"  = "http://${var.vip_address}:9696/v2.0/"
    "compute"  = "http://${var.vip_address}:8774/v2.1/"
    "image"    = "http://${var.vip_address}:9292/v2.0/"
  }
}

###############################################################################
# DATA SOURCE — read the EXISTING external network (created manually earlier).
# We don't manage it; we just reference it so our router can attach to it.
###############################################################################
data "openstack_networking_network_v2" "external" {
  name = var.external_network_name
}

###############################################################################
# 1. TENANT NETWORK + SUBNET  (the private network where the VM lives)
###############################################################################
resource "openstack_networking_network_v2" "tenant_net" {
  name           = "tf-net"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "tenant_subnet" {
  name            = "tf-subnet"
  network_id      = openstack_networking_network_v2.tenant_net.id
  cidr            = var.tenant_cidr
  ip_version      = 4
  gateway_ip      = cidrhost(var.tenant_cidr, 1) # .1 of the range
  dns_nameservers = ["1.1.1.1", "8.8.8.8"]

  allocation_pool {
    start = cidrhost(var.tenant_cidr, 10)  # .10
    end   = cidrhost(var.tenant_cidr, 200) # .200
  }
}

###############################################################################
# 2. ROUTER — bridges the tenant network to the external network.
#    external_network_id = the "public" side (SNAT for outbound).
#    The interface attaches the tenant subnet (the "private" side).
###############################################################################
resource "openstack_networking_router_v2" "router" {
  name                = "tf-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
}

resource "openstack_networking_router_interface_v2" "router_iface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.tenant_subnet.id
}

###############################################################################
# 3. SECURITY GROUP — the per-VM firewall. Allows inbound SSH + ICMP (ping),
#    and all outbound. Default OpenStack behaviour is deny-all inbound.
###############################################################################
resource "openstack_networking_secgroup_v2" "vm_access" {
  name        = "tf-vm-access"
  description = "Allow SSH and ICMP inbound (managed by Terraform)"
}

resource "openstack_networking_secgroup_rule_v2" "allow_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.vm_access.id
}

resource "openstack_networking_secgroup_rule_v2" "allow_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.vm_access.id
}

###############################################################################
# 4. KEYPAIR — your PUBLIC ssh key, injected into the VM at boot via cloud-init.
#    Points at the public key file on whichever machine runs Terraform.
###############################################################################
resource "openstack_compute_keypair_v2" "key" {
  name       = "tf-key"
  public_key = file(var.public_key_path)
}

###############################################################################
# 5. THE VM — boots from a cloud image, on the tenant network, with the
#    security group and keypair attached.
###############################################################################
resource "openstack_compute_instance_v2" "vm" {
  name            = "tf-vm"
  flavor_name     = var.flavor_name
  image_name      = var.image_name
  key_pair        = openstack_compute_keypair_v2.key.name
  security_groups = [openstack_networking_secgroup_v2.vm_access.name]

  network {
    uuid = openstack_networking_network_v2.tenant_net.id
  }

  # Make sure the router interface exists before the VM, so it has a
  # working route out the moment it boots.
  depends_on = [openstack_networking_router_interface_v2.router_iface]
}

###############################################################################
# 6. FLOATING IP — allocate from the external pool, associate to the VM.
###############################################################################

resource "openstack_networking_floatingip_v2" "fip" {
  pool = data.openstack_networking_network_v2.external.name
}

data "openstack_networking_port_v2" "vm_port" {
  device_id  = openstack_compute_instance_v2.vm.id
  network_id = openstack_networking_network_v2.tenant_net.id
}

resource "openstack_networking_floatingip_associate_v2" "fip_assoc" {
  floating_ip = openstack_networking_floatingip_v2.fip.address
  port_id     = data.openstack_networking_port_v2.vm_port.id
}

