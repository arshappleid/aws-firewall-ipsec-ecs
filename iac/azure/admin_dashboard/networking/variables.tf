variable "resource_group_name" {
  description = "Name of the Azure Resource Group to create."
  type        = string
  default     = "admin-dashboard-rg"
}

variable "location" {
  description = "Azure region for all networking resources."
  type        = string
  default     = "East US 2"
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network."
  type        = string
  default     = "10.10.0.0/16"
}

variable "subnet_prefix" {
  description = "CIDR block for the main subnet inside the VNet."
  type        = string
  default     = "10.10.1.0/24"
}
