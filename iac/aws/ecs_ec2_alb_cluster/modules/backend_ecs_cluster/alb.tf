module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.15.0"

  name                       = "${var.project_name}-api-alb"
  vpc_id                     = data.aws_vpc.backend.id
  subnets                    = data.aws_subnets.private.ids
  internal                   = true
  enable_deletion_protection = false

  # Use the existing security group instead of creating a new one
  create_security_group = false
  security_groups       = [aws_security_group.alb_sg.id]

  # HTTP-only listener — API Gateway terminates TLS, internal leg is plain HTTP
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = var.alb_default_target_service != null ? "${var.alb_default_target_service}-tg" : (length(var.services) > 0 ? "${keys(var.services)[0]}-tg" : null)
      }
    }
  }

  # Target groups dynamically created for each service
  target_groups = {
    for service_name, service_config in var.services : "${service_name}-tg" => {
      name_prefix                       = substr("${service_name}TG", 0, 6)
      protocol                          = "HTTP"
      port                              = 80
      target_type                       = service_config.target_type
      deregistration_delay              = 30
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        interval            = 35
        path                = service_config.health_check_path
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 3
        timeout             = 30
        protocol            = "HTTP"
        matcher             = "200"
      }

      create_attachment = false
    }
  }
  access_logs = {
    bucket  = "alb-logs-company"
    enabled = true
    prefix  = "access_logs"
  }
  tags = var.tags
}


# HTTP listener — routes all services with a path_pattern
resource "aws_lb_listener_rule" "service_path_routing_http" {
  for_each = {
    for service_name, service_config in var.services :
    service_name => service_config
    if lookup(service_config, "path_pattern", null) != null
  }

  listener_arn = module.alb.listeners["http"].arn
  priority     = try(each.value.alb_route_priority, index(keys(var.services), each.key) + 100)

  action {
    type             = "forward"
    target_group_arn = module.alb.target_groups["${each.key}-tg"].arn
  }

  condition {
    path_pattern {
      values = [each.value.path_pattern]
    }
  }

  dynamic "transform" {
    for_each = each.value.strip_path_prefix ? [1] : []
    content {
      type = "url-rewrite"
      url_rewrite_config {
        rewrite {
          regex   = "^${replace(each.value.path_pattern, "/*", "")}/(.*)$"
          replace = "/$1"
        }
      }
    }
  }

  tags = var.tags
}
