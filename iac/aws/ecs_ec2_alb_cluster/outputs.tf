# ECS Cluster Outputs
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs_cluster.ecs_cluster_id
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs_cluster.ecs_cluster_arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_cluster.ecs_cluster_name
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.ecs_cluster.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.ecs_cluster.alb_arn
}

output "alb_target_group_arns" {
  description = "ARNs of the ALB target groups"
  value       = module.ecs_cluster.alb_target_group_arns
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.ecs_cluster.alb_security_group_id
}

output "backend_security_group_id" {
  description = "ID of the backend ECS instances security group"
  value       = module.ecs_cluster.backend_security_group_id
}

output "iam_instance_profile_arn" {
  description = "ARN of the IAM instance profile for ECS instances"
  value       = module.ecs_cluster.iam_instance_profile_arn
}

output "on_demand_asg_name" {
  description = "Name of the on-demand autoscaling group"
  value       = module.ecs_cluster.on_demand_asg_name
}

output "spot_asg_name" {
  description = "Name of the spot autoscaling group"
  value       = module.ecs_cluster.spot_asg_name
}


# IAM Role Outputs
output "ec2_instance_role_arn" {
  description = "ARN of the IAM role for EC2 instances"
  value       = module.ecs_cluster.iam_instance_profile_arn
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role (for pulling images, logs, secrets)"
  value       = module.ecs_cluster.ecs_task_execution_role_arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role (runtime permissions for containers)"
  value       = module.ecs_cluster.ecs_task_role_arn
}
