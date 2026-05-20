locals {
  ecs_cluster_name = "${var.project_name}-ecs-cluster"
}

variable "sql_database_config" {
  description = "Configuration for the SQL database"
  default = {
    username = "company_admin"
    password = "Company!1234"
  }
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "company-backend"
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
