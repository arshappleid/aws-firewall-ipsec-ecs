# Virtual Network + Subnet
# https://registry.terraform.io/modules/Azure/network/azurerm/latest

module "network" {
  source  = "Azure/network/azurerm"
  version = "~> 5.3"

  resource_group_name = azurerm_resource_group.main.name
  vnet_name           = "admin-dashboard-vnet"
  address_spaces      = [var.vnet_address_space]
  subnet_prefixes     = [var.subnet_prefix]
  subnet_names        = ["admin-dashboard-subnet"]

  # use_for_each = true is recommended for new stacks (avoids count-based drift).
  use_for_each = true

  tags = local.common_tags

  depends_on = [azurerm_resource_group.main]
}
