variable "grafana_db_password" {
  description = "Password for the Grafana database user"
  default     = "M@r00n@dm1n"
  type        = string
  sensitive   = true
}

variable "grafana_admin_password" {
  description = "Password for the Grafana admin UI login"
  type        = string
  default     = "sacdaq-komrex-Zegwa3"
}

variable "tags" {
  default = {
    Owner = "Prabhmeet"
  }
}

variable "employee_ips" {
  description = "Employee public IP CIDRs allowed to SSH into bastion"
  type        = list(string)
  default     = ["73.2.7.207/32", "162.157.87.195/32"]
}

