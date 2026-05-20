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

# ── Resource Group ─────────────────────────────────────────────────────────────
# Created here (networking is the foundation layer).
# Downstream stacks (compute, compute_controls) reference it by name via var.
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

locals {
  common_tags = {
    project     = "admin-dashboard"
    environment = "production"
  }
}
