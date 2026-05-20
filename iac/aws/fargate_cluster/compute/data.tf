data "aws_lb_target_group" "chat_wss" {
  name = "chat-wss-tcp"
}

data "aws_iam_role" "ecs_task_role" {
  name = "Chat-WSS-ecs-task-role"
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "Chat-WSS-ecs-task-execution-role"
}

# Lookup the Central NLB by name
data "aws_lb" "nlb" {
  name = "Central-Network-Inpsection-NLB"
}
data "aws_security_group" "nlb_sg" {
  # This grabs the first SG ID from the list associated with the NLB
  id = one(data.aws_lb.nlb.security_groups)
}

data "aws_vpc" "backend" {
  tags = {
    Name = "backend-vpc"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.backend.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}
# Existing Cloud Map namespace for ECS Service Connect / service discovery
data "aws_service_discovery_dns_namespace" "this" {
  name = "datadog.internal"
  type = "DNS_PRIVATE"
}
