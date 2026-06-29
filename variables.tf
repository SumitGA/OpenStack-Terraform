variable "cloud_name" {
  description = "Name of the cloud entry in clouds.yaml"
  type        = string
  default     = "kolla-admin"
}

variable "vip_address" {
  description = "Internal VIP address of the OpenStack control plane"
  type        = string
  default     = "192.168.0.250"
}

variable "external_network_name" {
  description = "Name of the existing external/provider network"
  type        = string
  default     = "external-net"
}

variable "tenant_cidr" {
  description = "CIDR for the new Terraform-managed tenant network"
  type        = string
  default     = "10.10.0.0/24"
}

variable "image_name" {
  description = "Glance image to boot (must be a CLOUD image, not an installer ISO)"
  type        = string
  default     = "ubuntu-24.04"
}

variable "flavor_name" {
  description = "Flavor (size) for the VM"
  type        = string
  default     = "m1.small"
}

variable "public_key_path" {
  description = "Path to the SSH public key to inject into the VM"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}
