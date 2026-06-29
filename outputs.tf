###############################################################################
# outputs.tf
# Values Terraform prints after apply — most importantly the floating IP and
# a ready-to-paste SSH command.
###############################################################################

output "vm_name" {
  description = "Name of the created VM"
  value       = openstack_compute_instance_v2.vm.name
}

output "vm_private_ip" {
  description = "Private (tenant) IP of the VM"
  value       = openstack_compute_instance_v2.vm.access_ip_v4
}

output "vm_floating_ip" {
  description = "Public/floating IP assigned to the VM"
  value       = openstack_networking_floatingip_v2.fip.address
}

output "ssh_command" {
  description = "Ready-to-use SSH command (run from a host that can reach the floating IP)"
  value       = "ssh ubuntu@${openstack_networking_floatingip_v2.fip.address}"
}

