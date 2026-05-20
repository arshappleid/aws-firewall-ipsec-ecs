# ECS Cluster Module - encapsulates all ECS infrastructure including VPC
module "ecs_cluster" {
  source = "./modules/backend_ecs_cluster"

  project_name = var.project_name
  tags         = var.tags

  alb_default_target_service = "backend"

  # Cluster Configuration
  cluster_config = {
    spot_instance_percentage = 80

    # EC2 Instance Configuration
    # Capacity Requirements - 4vCPU, or 2xLarge Instances
    ecs_instance_type_on_demand = "c6g.xlarge"
    ecs_instance_types_spot     = ["c6g.2xlarge", "c6gd.2xlarge", "c7g.2xlarge", "c7gd.2xlarge", "c7gn.2xlarge", "m7g.2xlarge", "m7gd.2xlarge", "m6g.2xlarge", "t4g.2xlarge", "r6g.2xlarge", "r7g.2xlarge"]
    ebs_volume_size             = 30

    # ASG Configuration - On-demand as fallback only
    on_demand_min_size         = 0
    on_demand_max_size         = 1
    on_demand_desired_capacity = 0

    # Spot for primary capacity
    spot_min_size         = 1
    spot_max_size         = 5
    spot_desired_capacity = 1

    # Monitoring
    enable_monitoring         = false
    health_check_grace_period = 300
  }

  # Services Configuration
  // ip = 
  services = {
    backend = {
      container_port     = 80
      health_check_path  = "/health"
      desired_task_count = 1
      path_pattern       = "/v1/*"
      alb_route_priority = 50
      strip_path_prefix  = true
      target_type        = "instance"

      enable_execute_command = true

      # Task Definition
      task_family = "backend-service1-flask-api-task-definition"
      task_cpu    = 768
      task_memory = 768 # headroom above 563 MB total observed across all containers
    }
    chat = {
      container_port     = 80
      health_check_path  = "/health"
      desired_task_count = 1
      path_pattern       = "/chat/*"
      alb_route_priority = 60
      target_type        = "instance"
      https_only         = true

      enable_execute_command = true

      # Task Definition
      task_family = "backend-service-chat-api-task-definition"
      task_cpu    = 768
      task_memory = 768 # headroom above 563 MB total observed across all containers
    }
    analytics = {
      container_port     = 80
      health_check_path  = "/health"
      desired_task_count = 1
      path_pattern       = "/analytics/*"
      alb_route_priority = 5
      target_type        = "instance"

      enable_execute_command = true

      # Task Definition
      task_family = "backend-analytics-api-task-definition"
      task_cpu    = 256
      task_memory = 256
    }
    security = {
      container_port     = 80
      health_check_path  = "/health"
      desired_task_count = 1
      path_pattern       = "/security/*"
      alb_route_priority = 40
      target_type        = "instance"

      enable_execute_command = true

      # Task Definition
      task_family = "security-service-task-definition"
      task_cpu    = 128
      task_memory = 128
    }

    passkey = {
      container_port     = 80
      health_check_path  = "/health"
      desired_task_count = 1
      path_pattern       = "/passkey/*"
      alb_route_priority = 10
      target_type        = "instance"

      enable_execute_command = true

      # Task Definition
      task_family = "passkey-service-task-definition"
      task_cpu    = 128
      task_memory = 128
    }


  }

  # ALB Configuration
  # HTTP listener forwards directly - API Gateway terminates TLS, internal leg is plain HTTP
  alb_listeners = {
    http = {
      port              = 80
      protocol          = "HTTP"
      redirect_to_https = false
    }
  }

  ## These security groups reference each other, to control traffic between ALB and ECS instances
  # No open internet ingress - ALB only accepts traffic from API Gateway VPC Link (see below)
  alb_security_group_ingress = {}

  # Backend ECS instances security group configuration
  ecs_security_group_ingress = {
    dynamic_ports = {
      from_port   = 32768
      to_port     = 65535
      protocol    = "tcp"
      description = "Dynamic container ports from ALB only"
    }
  }

  # Scaling Configuration
  scale_up_cpu_threshold = 95
}

# ─── Allow API Gateway VPC Link → ALB ────────────────────────────────────────
# Separate state, so look up the VPC link SG by name tag
data "aws_security_group" "apigw_vpc_link" {
  tags = {
    Name = "apigw-vpc-link-sg"
  }
}

resource "aws_security_group_rule" "alb_from_apigw_vpc_link" {
  type                     = "ingress"
  description              = "HTTPS from API Gateway VPC Link"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.apigw_vpc_link.id
  security_group_id        = module.ecs_cluster.alb_security_group_id
}

# Look up the latest active revision for each task family
data "aws_ecs_task_definition" "latest" {
  for_each        = module.ecs_cluster.services_config
  task_definition = each.value.task_family
}

# Create minimal task definitions for each service - used for bootstrapping
resource "aws_ecs_task_definition" "service" {
  for_each = module.ecs_cluster.services_config

  family                   = each.value.task_family
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = tostring(each.value.task_cpu)
  memory                   = tostring(each.value.task_memory)
  execution_role_arn       = module.ecs_cluster.ecs_task_execution_role_arn
  task_role_arn            = module.ecs_cluster.ecs_task_role_arn

  container_definitions = jsonencode([{
    name      = try(jsondecode(data.aws_ecs_task_definition.latest[each.key].container_definitions)[0].name, each.key)
    image     = each.value.image
    cpu       = each.value.task_cpu
    memory    = each.value.task_memory
    essential = true
    portMappings = [{
      containerPort = each.value.container_port
      hostPort      = 0 # Dynamic port — bridge mode, ECS assigns a random host port
      protocol      = "tcp"
    }]
  }])

  # CI/CD manages container_definitions and resource sizing — Terraform must not overwrite them
  lifecycle {
    ignore_changes = [container_definitions, network_mode, cpu, memory, execution_role_arn, task_role_arn]
  }

  tags = var.tags
}

# Create ECS services for each service config
resource "aws_ecs_service" "service" {
  for_each = module.ecs_cluster.services_config

  name    = each.key
  cluster = module.ecs_cluster.ecs_cluster_id

  # Always point to the latest revision found in AWS
  task_definition                   = data.aws_ecs_task_definition.latest[each.key].arn
  desired_count                     = each.value.desired_task_count
  health_check_grace_period_seconds = 150
  force_new_deployment              = true
  enable_execute_command            = each.value.enable_execute_command

  # Capacity provider strategy — spot-first, on-demand only as fallback
  capacity_provider_strategy {
    capacity_provider = module.ecs_cluster.capacity_provider_spot_name
    weight            = 100
    base              = 1 # first task always goes to spot
  }
  capacity_provider_strategy {
    capacity_provider = module.ecs_cluster.capacity_provider_on_demand_name
    weight            = 0 # only used when spot is unavailable
  }

  # Deployment configuration
  deployment_minimum_healthy_percent = each.value.deployment_minimum_healthy_percent
  deployment_maximum_percent         = each.value.deployment_maximum_percent

  # Placement strategy
  dynamic "ordered_placement_strategy" {
    for_each = each.value.placement_strategy
    content {
      type  = ordered_placement_strategy.value.type
      field = ordered_placement_strategy.value.field
    }
  }

  # Load balancer configuration
  load_balancer {
    target_group_arn = module.ecs_cluster.alb_target_group_arns["${each.key}-tg"].arn
    container_name   = jsondecode(data.aws_ecs_task_definition.latest[each.key].container_definitions)[0].name
    container_port   = each.value.container_port
  }

  # Only ignore desired_count now; task_definition is tracked via the "latest" data source
  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = var.tags
}
