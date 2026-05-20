output "resource_group_name" {
  description = "Name of the Resource Group. Pass to: compute var.resource_group_name, compute_controls var.resource_group_name."
  value       = azurerm_resource_group.main.name
}

output "location" {
  description = "Azure region. Pass to: compute var.location, compute_controls var.location."
  value       = azurerm_resource_group.main.location
}

output "vnet_id" {
  description = "ID of the Virtual Network."
  value       = module.network.vnet_id
}

output "vnet_name" {
  description = "Name of the Virtual Network. Used by compute remote state lookup."
  value       = module.network.vnet_name
}

output "subnet_name" {
  description = "Name of the main subnet. Used by compute remote state lookup."
  value       = "admin-dashboard-subnet"
}

output "nsg_name" {
  description = "Name of the NSG. Used by compute remote state lookup."
  value       = azurerm_network_security_group.main.name
}

output "subnet_id" {
  description = "ID of the main subnet."
  value       = module.network.vnet_subnets[0]
}

output "nsg_id" {
  description = "ID of the Network Security Group."
  value       = azurerm_network_security_group.main.id
}
