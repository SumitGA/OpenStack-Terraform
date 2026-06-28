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
