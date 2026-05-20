locals {
  service_common_config = {
    enable_execute_command                 = true  # Enable ECS Exec for terminal access
    ignore_task_definition_changes         = true  # Allow CI/CD to manage task definition updates
    create_task_definition                 = false # Create initial task definition
    task_definition_arn                    = "arn:aws:ecs:us-east-2:156041414531:task-definition/backend-service-chat-wss-task-definition:14"
    cpu                                    = var.service_1_config.service_cpu_allocation
    memory                                 = var.service_1_config.service_memory_allocation
    cloudwatch_log_group_class             = var.logs_retention_config.class
    cloudwatch_log_group_retention_in_days = var.logs_retention_config.retention_in_days

    task_exec_iam_role_arn = data.aws_iam_role.ecs_task_execution_role.arn
    tasks_iam_role_arn     = data.aws_iam_role.ecs_task_role.arn
    container_definitions  = {}

    load_balancer = {
      service = {
        target_group_arn = data.aws_lb_target_group.chat_wss.arn
        container_name   = var.service_1_config.name
        container_port   = var.service_1_config.container_port
      }
    }

    subnet_ids = [tolist(data.aws_subnets.private.ids)[1]] ## Deploy in second private subnet
    security_group_ingress_rules = {
      nlb_80 = {
        description = "Service port"
        from_port   = var.service_1_config.container_port
        ip_protocol = "tcp"
        cidr_ipv4   = "192.168.1.0/26"
      }
    }
    security_group_egress_rules = {
      https = {
        description = "Allow all HTTPS"
        from_port   = 443
        to_port     = 443
        ip_protocol = "tcp"
        cidr_ipv4   = "0.0.0.0/0"
      }
      http_internal = {
        description = "Allow HTTP to internal network"
        from_port   = 80
        to_port     = 80
        ip_protocol = "tcp"
        cidr_ipv4   = "10.0.0.0/8"
      }
      datadog_apm_traces = {
        description = "Datadog APM Traces"
        from_port   = 8126
        to_port     = 8126
        ip_protocol = "tcp"
        cidr_ipv4   = "10.0.0.0/16"
      }
      datadog_dogstatsd_metrics = {
        description = "Datadog DogStatsD Metrics"
        from_port   = 8125
        to_port     = 8125
        ip_protocol = "udp"
        cidr_ipv4   = "10.0.0.0/16"
      }
      datadog_agent_api = {
        description = "Datadog Agent API / Config"
        from_port   = 5001
        to_port     = 5001
        ip_protocol = "tcp"
        cidr_ipv4   = "10.0.0.0/16"
      }
    }
  }

  service_variants = {
    spot = {
      desired_count = var.service_1_config.desired_count
      capacity_provider_strategy = {
        FARGATE_SPOT = {
          capacity_provider = "FARGATE_SPOT"
          weight            = 1
        }
      }
    }
    "on-demand" = {
      desired_count = 0
      capacity_provider_strategy = {
        FARGATE = {
          capacity_provider = "FARGATE"
          weight            = 1
        }
      }
    }
  }
}

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name                           = "${var.tags.Application}-ecs-cluster"
  cloudwatch_log_group_class             = var.logs_retention_config.class
  cloudwatch_log_group_retention_in_days = var.logs_retention_config.retention_in_days

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/ApplicationLogs/backend/${var.tags.Application}/"
      }
    }
  }


  # Cluster capacity providers — FARGATE_SPOT first, FARGATE as fallback
  cluster_capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy = {
    FARGATE_SPOT = {
      weight = 100
      base   = 1
    }
    FARGATE = {
      weight = 0 # only used when spot is unavailable
    }
  }
  ## Services 

  services = {
    for suffix, cfg in local.service_variants : "${var.service_1_config.name}-${suffix}" => merge(
      local.service_common_config,
      {
        desired_count              = cfg.desired_count
        capacity_provider_strategy = cfg.capacity_provider_strategy
      }
    )
  }

  tags = var.tags
}


