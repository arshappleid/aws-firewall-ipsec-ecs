# Linux Virtual Machine — admin-dashboard
# https://registry.terraform.io/modules/Azure/compute/azurerm/latest
#
# Networking is resolved via data sources (main.tf) — no IDs need to be
# passed in from the networking stack, just the resource group name.
#
# The VM will be named: <vm_hostname>-vmLinux-0  (module default naming template)
# i.e. with defaults:   admin-dashboard-vmLinux-0

module "vm" {
  source  = "Azure/compute/azurerm"
  version = "~> 5.3"

  resource_group_name = data.terraform_remote_state.networking.outputs.resource_group_name

  # ── Identity ───────────────────────────────────────────────────────────────
  vm_hostname    = var.vm_hostname
  admin_username = var.admin_username
  admin_password = var.admin_password
  enable_ssh_key = false

  # ── Size & OS ──────────────────────────────────────────────────────────────
  vm_size              = var.vm_size # set in variables.tf — see size options there
  storage_account_type = "Standard_LRS"
  data_sa_type         = "Standard_LRS"
  vm_os_publisher      = "Canonical"
  vm_os_offer          = "0001-com-ubuntu-server-jammy"
  vm_os_sku            = "22_04-lts-gen2"
  nb_instances         = 1

  # ── Networking (resolved via data sources) ────────────────────────────────
  vnet_subnet_id = data.azurerm_subnet.main.id

  # Bring-your-own NSG: disables the module's auto-created single-port NSG
  # and associates the networking stack's NSG (ports 22 + 80) with the NIC.
  network_security_group = {
    id = data.azurerm_network_security_group.main.id
  }

  # ── Public IP ──────────────────────────────────────────────────────────────
  nb_public_ip      = 1
  allocation_method = "Static"
  public_ip_sku     = "Standard"
  public_ip_dns     = ["admin-dashboard-pip"] # <label>.eastus.cloudapp.azure.com

  # ── Cloud-init startup script ──────────────────────────────────────────────
  # Installs Docker + Docker Compose v2 and clones var.github_repo_url to /opt/app.
  custom_data = templatefile("${path.module}/cloud_init.yaml", {
    admin_username  = var.admin_username
    github_repo_url = var.github_repo_url
    github_branch   = var.github_branch
    github_pat      = var.github_pat
    domain_name     = var.domain_name
    app_port        = var.app_port
  })

  tags = local.common_tags
}
