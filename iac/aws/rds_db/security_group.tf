

# Allows traffic from your current machine (for testing) or App Runner/Lambda
resource "aws_security_group" "rds_sg" {
  name        = "company-rds-sg-2"
  description = "Allow only outbound traffic by default"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "PostgreSQL from Bastion host"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [data.aws_security_group.bastion.id]
  }

  ingress {
    description     = "PostgreSQL from Backend ECS cluster"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [data.aws_security_group.backend_ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

