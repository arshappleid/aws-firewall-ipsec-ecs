# ─────────────────────────────────────────────────────────────────────────────
# Azure Automation — scheduled VM start / stop
#
# Prereqs (run compute/ first):
#   var.vm_name            ← compute: terraform output vm_name
#   var.resource_group_name← networking: terraform output resource_group_name
#   var.location           ← networking: terraform output location
#
# Schedules (America/New_York handles EST↔EDT automatically):
#   Start — 11:00 AM Eastern Time  every day
#   Stop  — 11:59 PM Eastern Time  every day
#
# Auth: System-Assigned Managed Identity granted
#       "Virtual Machine Contributor" on the resource group.
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_automation_account" "vm_scheduler" {
  name                = "admin-dashboard-scheduler"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Basic"

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Look up the resource group so we can scope the role assignment correctly.
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_role_assignment" "automation_vm_contributor" {
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_automation_account.vm_scheduler.identity[0].principal_id
}

# ─── Start VM runbook ─────────────────────────────────────────────────────────

resource "azurerm_automation_runbook" "start_vm" {
  name                    = "Start-AdminDashboard"
  location                = var.location
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.vm_scheduler.name
  log_verbose             = false
  log_progress            = true
  description             = "Start admin-dashboard VM — fires daily at 11:00 AM Eastern Time"
  runbook_type            = "PowerShell72"

  content = <<-PWSH
    param(
        [string]$ResourceGroupName = "${var.resource_group_name}",
        [string]$VMName            = "${var.vm_name}"
    )

    Write-Output "$(Get-Date -Format u) | Connecting via managed identity..."
    Connect-AzAccount -Identity | Out-Null

    Write-Output "$(Get-Date -Format u) | Starting VM '$VMName' in '$ResourceGroupName'..."
    $result = Start-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
    Write-Output "$(Get-Date -Format u) | Done. Status: $($result.Status)"
  PWSH
}

# ─── Stop VM runbook ──────────────────────────────────────────────────────────

resource "azurerm_automation_runbook" "stop_vm" {
  name                    = "Stop-AdminDashboard"
  location                = var.location
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.vm_scheduler.name
  log_verbose             = false
  log_progress            = true
  description             = "Stop admin-dashboard VM — fires daily at 11:59 PM Eastern Time"
  runbook_type            = "PowerShell72"

  content = <<-PWSH
    param(
        [string]$ResourceGroupName = "${var.resource_group_name}",
        [string]$VMName            = "${var.vm_name}"
    )

    Write-Output "$(Get-Date -Format u) | Connecting via managed identity..."
    Connect-AzAccount -Identity | Out-Null

    Write-Output "$(Get-Date -Format u) | Stopping VM '$VMName' in '$ResourceGroupName'..."
    $result = Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force
    Write-Output "$(Get-Date -Format u) | Done. Status: $($result.Status)"
  PWSH
}

# ─── Schedules ────────────────────────────────────────────────────────────────
# timezone = "America/New_York" observes daylight-saving transitions automatically.
# ignore_changes on start_time prevents Terraform from drifting after creation.

resource "azurerm_automation_schedule" "start_vm" {
  name                    = "daily-start-11am-et"
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.vm_scheduler.name
  frequency               = "Day"
  interval                = 1
  timezone                = "America/New_York"
  start_time              = "2026-03-07T11:00:00-05:00"
  description             = "Fires every day at 11:00 AM Eastern Time"

  lifecycle {
    ignore_changes = [start_time]
  }
}

resource "azurerm_automation_schedule" "stop_vm" {
  name                    = "daily-stop-1159pm-et"
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.vm_scheduler.name
  frequency               = "Day"
  interval                = 1
  timezone                = "America/New_York"
  start_time              = "2026-03-07T23:59:00-05:00"
  description             = "Fires every day at 11:59 PM Eastern Time"

  lifecycle {
    ignore_changes = [start_time]
  }
}

# ─── Link schedules → runbooks ────────────────────────────────────────────────

resource "azurerm_automation_job_schedule" "start_vm" {
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.vm_scheduler.name
  schedule_name           = azurerm_automation_schedule.start_vm.name
  runbook_name            = azurerm_automation_runbook.start_vm.name
}

resource "azurerm_automation_job_schedule" "stop_vm" {
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.vm_scheduler.name
  schedule_name           = azurerm_automation_schedule.stop_vm.name
  runbook_name            = azurerm_automation_runbook.stop_vm.name
}
