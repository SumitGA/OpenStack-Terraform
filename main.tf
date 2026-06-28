terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.0"
    }
  }
}

provider "openstack" {
  cloud = "kolla-admin"   # matches the entry in clouds.yaml

  endpoint_overrides = {
    "identity" = "http://192.168.0.250:5000/v3/"
    "network" = "http://192.168.0.250:9696/v2.0/"
    "compute" = "http://192.168.0.250:8774/v2.1/"
    "image" = "http://192.168.0.250:9292/"
  }
}

# Data source = READ-ONLY lookup of something that already exists.
# This reads your existing external network. Creates nothing.
data "openstack_networking_network_v2" "external" {
  name = "external-net"
}

output "external_network_id" {
  value = data.openstack_networking_network_v2.external.id
}

# A NEW network, defined in code. Named tf-* 
resource "openstack_networking_network_v2" "tf_net" {
  name           = "tf-net"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "tf_subnet" {
  name            = "tf-subnet"
  network_id      = openstack_networking_network_v2.tf_net.id
  cidr            = "10.10.0.0/24"
  ip_version      = 4
  dns_nameservers = ["1.1.1.1"]
}
