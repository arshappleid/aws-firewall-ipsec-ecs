output "automation_account_name" {
  description = "Name of the Azure Automation Account."
  value       = azurerm_automation_account.vm_scheduler.name
}

output "automation_account_id" {
  description = "ID of the Azure Automation Account."
  value       = azurerm_automation_account.vm_scheduler.id
}

output "start_runbook_name" {
  description = "Name of the start-VM runbook."
  value       = azurerm_automation_runbook.start_vm.name
}

output "stop_runbook_name" {
  description = "Name of the stop-VM runbook."
  value       = azurerm_automation_runbook.stop_vm.name
}

output "start_schedule_name" {
  description = "Name of the daily 11:00 AM ET start schedule."
  value       = azurerm_automation_schedule.start_vm.name
}

output "stop_schedule_name" {
  description = "Name of the daily 11:59 PM ET stop schedule."
  value       = azurerm_automation_schedule.stop_vm.name
}
