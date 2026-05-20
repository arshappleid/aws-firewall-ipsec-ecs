variable "tags" {
  description = "Tags to apply to all resources. 'Application' key is used for resource naming."
  type        = map(string)
  default = {
    Owner       = "Prabhmeet"
    Application = "Chat-WSS"
  }
}

variable "logs_retention_config" {
  description = "CloudWatch log group configuration shared across the cluster and services."
  type = object({
    class             = string
    retention_in_days = number
  })
  default = {
    class             = "STANDARD"
    retention_in_days = 30
  }
}

variable "cluster_config" {
  description = "ECS cluster capacity provider configuration."
  type = object({
    spot_instance_percentage = number
  })
  default = {
    spot_instance_percentage = 60
  }
}
// Chat Websocket Service
variable "service_1_config" {
  description = "Configuration for the frontend ECS service."
  type = object({
    name                      = string
    desired_count             = number
    container_port            = number
    port_name                 = string
    service_cpu_allocation    = number
    service_memory_allocation = number
  })

  default = {
    name                      = "chat-wss"
    desired_count             = 1
    container_port            = 80
    port_name                 = "http"
    service_cpu_allocation    = 256
    service_memory_allocation = 512
  }
}
/*
variable "service_2_config" {
  description = "Configuration for the backend ECS service."
  type = object({
    name           = string
    container_port = number
    port_name      = string
  })
}

*/
