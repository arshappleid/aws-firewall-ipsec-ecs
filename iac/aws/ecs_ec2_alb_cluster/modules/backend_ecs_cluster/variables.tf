# Project Configuration
variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}

# Cluster Configuration
variable "cluster_config" {
  description = "Configuration for the ECS cluster"
  type = object({
    spot_instance_percentage = optional(number, 50)

    # EC2 Instance Configuration
    ecs_instance_type_on_demand = optional(string, "t3a.xlarge")
    ecs_instance_types_spot     = optional(list(string), ["t3.medium", "t3a.medium", "t2.medium"])
    ebs_volume_size             = optional(number, 30)
    on_demand_volume_type       = optional(string, "gp2")
    spot_volume_type            = optional(string, "gp3")

    # Auto Scaling Group Configuration
    on_demand_min_size         = optional(number, 1)
    on_demand_max_size         = optional(number, 3)
    on_demand_desired_capacity = optional(number, 1)
    spot_min_size              = optional(number, 0)
    spot_max_size              = optional(number, 5)
    spot_desired_capacity      = optional(number, 1)

    # Monitoring
    enable_monitoring         = optional(bool, true)
    health_check_grace_period = optional(number, 300)
  })
  default = {}
}

# Services Configuration
variable "services" {
  description = "Map of ECS services to create with their configurations"
  type = map(object({
    container_port     = number
    health_check_path  = optional(string, "/health")
    desired_task_count = optional(number, 2)
    port_name          = optional(string, "http")

    # ALB Path-based Routing
    path_pattern       = optional(string) # e.g., "/api/*" or "/v1/*"
    alb_route_priority = optional(number) # Lower number = higher priority (1-50000)
    strip_path_prefix  = optional(bool, true)
    target_type        = optional(string, "instance") # "instance" for bridge mode, "ip" for awsvpc
    https_only         = optional(bool, false)        # if true, also adds rule to HTTPS listener

    # Task Definition Configuration
    task_family    = string
    container_name = optional(string, "api")
    image          = optional(string, "public.ecr.aws/docker/library/nginx:alpine")
    task_cpu       = optional(number, 256)
    task_memory    = optional(number, 512)

    # Placement Strategy
    placement_strategy = optional(list(object({
      type  = string # "spread", "binpack", or "random"
      field = string # e.g., "attribute:ecs.availability-zone", "memory", "cpu"
      })), [
      {
        type  = "spread"
        field = "attribute:ecs.availability-zone"
      },
      {
        type  = "binpack"
        field = "memory"
      }
    ])

    # Deployment Configuration
    deployment_minimum_healthy_percent = optional(number, 50)
    deployment_maximum_percent         = optional(number, 200)

    # CI/CD Integration
    ignore_task_definition_changes = optional(bool, true)

    # ECS Exec
    enable_execute_command = optional(bool, false)
  }))
  default = {}

  validation {
    condition     = alltrue([for name, config in var.services : can(regex("^[a-z0-9-]+$", name))])
    error_message = "Service names must contain only lowercase letters, numbers, and hyphens."
  }
}

# ALB Configuration (HTTP-only — API Gateway terminates TLS)
# The alb_listeners variable is kept for backwards compatibility but no longer drives listener creation.
variable "alb_listeners" {
  description = "Unused — kept for interface compatibility. ALB is hardcoded to HTTP:80."
  type        = any
  default     = {}
}

# Security Group Configuration
variable "alb_security_group_ingress" {
  description = "Map of ingress rules for ALB security group"
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = {
    http = {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP from internet"
    }
  }
}

variable "ecs_security_group_ingress" {
  description = "Map of ingress rules for backend ECS instances security group"
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
  }))
  default = {
    dynamic_ports = {
      from_port   = 32768
      to_port     = 65535
      protocol    = "tcp"
      description = "Dynamic container ports from ALB only"
    }
  }
}

# ECS Capacity Provider Configuration
variable "on_demand_managed_scaling" {
  description = "Managed scaling configuration for on-demand capacity provider"
  type = object({
    maximum_scaling_step_size = number
    minimum_scaling_step_size = number
    status                    = string
    target_capacity           = number
  })
  default = {
    maximum_scaling_step_size = 2
    minimum_scaling_step_size = 1
    status                    = "ENABLED"
    target_capacity           = 80
  }
}

variable "spot_managed_scaling" {
  description = "Managed scaling configuration for spot capacity provider"
  type = object({
    maximum_scaling_step_size = number
    minimum_scaling_step_size = number
    status                    = string
    target_capacity           = number
  })
  default = {
    maximum_scaling_step_size = 10
    minimum_scaling_step_size = 1
    status                    = "ENABLED"
    target_capacity           = 100
  }
}

variable "alb_default_target_service" {
  description = "The service name to use as the default ALB target group (must be a key in var.services)"
  type        = string
  default     = null
}

# Scaling Policy Configuration
variable "scale_up_cpu_threshold" {
  description = "CPU percentage threshold to trigger scale up"
  type        = number
  default     = 70
}
