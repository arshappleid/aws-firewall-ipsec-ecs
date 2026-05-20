# Security group for ALB (public-facing)
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg-internet-facing"
  description = "Security group for ALB - allows public traffic"
  vpc_id      = data.aws_vpc.backend.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ALB ingress rules
resource "aws_security_group_rule" "alb_ingress" {
  for_each = var.alb_security_group_ingress

  type              = "ingress"
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  security_group_id = aws_security_group.alb_sg.id
}

# ALB egress rule
resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  description       = "Allow all outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

# Security group for ECS instances (private - only ALB access)
resource "aws_security_group" "backend_sg" {
  name        = "${var.project_name}-ecs-instances-sg-alb-to-cluster"
  description = "Security group for ECS instances - only allows ALB traffic"
  vpc_id      = data.aws_vpc.backend.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-ecs-instances-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ECS instances ingress rules (from ALB)
resource "aws_security_group_rule" "backend_ingress" {
  for_each = var.ecs_security_group_ingress

  type                     = "ingress"
  description              = each.value.description
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = aws_security_group.backend_sg.id
}

# Datadog log ingestion - HTTP (HTTPS)
resource "aws_security_group_rule" "datadog_logs_https" {
  type              = "ingress"
  description       = "Datadog log ingestion over HTTP"
  from_port         = 10518
  to_port           = 10518
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.backend_sg.id
}

# Datadog log ingestion - TCP
resource "aws_security_group_rule" "datadog_logs_tcp" {
  type              = "ingress"
  description       = "Datadog trace ingestion over TCP"
  from_port         = 8126
  to_port           = 8126
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.backend_sg.id
}

# Datadog log ingestion - UDP
resource "aws_security_group_rule" "datadog_logs_udp" {
  type              = "ingress"
  description       = "Datadog trace ingestion over UDP"
  from_port         = 8125
  to_port           = 8125
  protocol          = "udp"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.backend_sg.id
}

# ECS instances egress rule
resource "aws_security_group_rule" "backend_egress" {
  type              = "egress"
  description       = "Allow all outbound (for pulling images, etc)"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend_sg.id
}


