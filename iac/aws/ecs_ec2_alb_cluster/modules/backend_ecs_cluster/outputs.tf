output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs_cluster.id
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs_cluster.arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_cluster.name
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.alb.dns_name
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = module.alb.arn
}

output "alb_target_group_arns" {
  description = "ARNs of the target groups"
  value       = module.alb.target_groups
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb_sg.id
}

output "backend_security_group_id" {
  description = "ID of the backend ECS instances security group"
  value       = aws_security_group.backend_sg.id
}

output "iam_instance_profile_arn" {
  description = "ARN of the IAM instance profile for ECS instances"
  value       = aws_iam_instance_profile.backend_ec2_profile.arn
}

output "iam_role_name" {
  description = "Name of the IAM role for ECS instances"
  value       = aws_iam_role.backend_ec2_role.name
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_execution_role_name" {
  description = "Name of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.name
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "ecs_task_role_name" {
  description = "Name of the ECS task role"
  value       = aws_iam_role.ecs_task_role.name
}

output "on_demand_asg_name" {
  description = "Name of the on-demand autoscaling group"
  value       = module.asg_ecs_on_demand.autoscaling_group_name
}

output "spot_asg_name" {
  description = "Name of the spot autoscaling group"
  value       = module.asg_ecs_spot.autoscaling_group_name
}

output "capacity_provider_on_demand_name" {
  description = "Name of the on-demand capacity provider"
  value       = module.ecs_cluster.autoscaling_capacity_providers["on_demand"].name
}

output "capacity_provider_spot_name" {
  description = "Name of the spot capacity provider"
  value       = module.ecs_cluster.autoscaling_capacity_providers["spot"].name
}

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = data.aws_vpc.backend.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = data.aws_vpc.backend.cidr_block
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = tolist(data.aws_route_tables.private.ids)
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = data.aws_subnets.private.ids
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = data.aws_subnets.public.ids
}

# Services Configuration Output
output "services_config" {
  description = "Services configuration map"
  value       = var.services
}

# Cluster Configuration Output
output "cluster_config" {
  description = "Cluster configuration"
  value       = var.cluster_config
}

output "alb_https_listener_arn" {
  description = "ARN of the ALB HTTPS listener"
  value       = try(module.alb.listeners["https"].arn, null)
}

output "alb_http_listener_arn" {
  description = "ARN of the ALB HTTP listener"
  value       = try(module.alb.listeners["http"].arn, null)
}

output "ecs_datadog_task_execution_role_arn" {
  description = "ARN of the Datadog agent ECS task execution role"
  value       = aws_iam_role.ecs_datadog_task_execution_role.arn
}

output "ecs_datadog_task_role_arn" {
  description = "ARN of the Datadog agent ECS task role"
  value       = aws_iam_role.ecs_datadog_task_role.arn
}
