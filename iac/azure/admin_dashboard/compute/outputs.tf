output "vm_name" {
  description = "Full VM name as provisioned by the module. Pass to: compute_controls var.vm_name."
  value       = local.vm_name
}

output "vm_public_ip" {
  description = "Static public IP address of the admin-dashboard VM."
  value       = module.vm.public_ip_address[0]
}

output "vm_public_fqdn" {
  description = "Public DNS FQDN (e.g. admin-dashboard-pip.eastus.cloudapp.azure.com)."
  value       = module.vm.public_ip_dns_name
}

output "ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ${var.admin_username}@${module.vm.public_ip_address[0]}"
}

output "http_url" {
  description = "HTTP URL for the admin dashboard."
  value       = "http://${module.vm.public_ip_address[0]}"
}

output "nsg_id" {
  description = "ID of the NSG associated with the VM NIC."
  value       = module.vm.network_security_group_id
}

