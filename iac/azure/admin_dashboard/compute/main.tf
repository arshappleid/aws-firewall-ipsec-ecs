terraform {
  required_version = ">= 1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.11, < 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  common_tags = {
    project     = "admin-dashboard"
    environment = "production"
  }

  # Matches the Azure/compute/azurerm module's default Linux naming template:
  # "${vm_hostname}-vmLinux-${host_number}" — with nb_instances = 1 → index 0.
  vm_name = "${var.vm_hostname}-Linux-vm"
}

# ── Networking stack remote state ────────────────────────────────────────────
# Reads all outputs from the networking/ stack's local state file automatically.
# No networking variables need to be passed into this stack manually.
data "terraform_remote_state" "networking" {
  backend = "local"
  config = {
    path = "${path.module}/../networking/terraform.tfstate"
  }
}

# ── Data sources — resolve networking resources from remote state outputs ─────

data "azurerm_subnet" "main" {
  name                 = data.terraform_remote_state.networking.outputs.subnet_name
  virtual_network_name = data.terraform_remote_state.networking.outputs.vnet_name
  resource_group_name  = data.terraform_remote_state.networking.outputs.resource_group_name
}

data "azurerm_network_security_group" "main" {
  name                = data.terraform_remote_state.networking.outputs.nsg_name
  resource_group_name = data.terraform_remote_state.networking.outputs.resource_group_name
}
