variable "Application_name" {
  description = "A name used to Manage and Identify resources"
  type        = string
  default     = "companypostgres"
}
variable "db_username" {
  description = "Username for the master DB user"
  type        = string
  default     = "company_admin"
}
variable "db_password" {
  description = "Password for the master DB user"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default = {
    Application = "Backend-Flask-API"
    Environment = "dev"
    Owner       = "Prabhmeet"
  }
}
