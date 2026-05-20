variable "resource_group_name" {
  description = "Name of the existing Resource Group (created by the networking stack)."
  type        = string
  default     = "admin-dashboard-rg"
}

variable "location" {
  description = "Azure region — must match the networking stack's location."
  type        = string
  default     = "East US 2"
}

variable "vm_name" {
  description = "Full VM name output from the compute stack (compute: terraform output vm_name)."
  type        = string
  # Default matches the Azure/compute/azurerm module's naming template with vm_hostname = "admin-dashboard".
  default = "admin-dashboard-vmLinux-0"
}
