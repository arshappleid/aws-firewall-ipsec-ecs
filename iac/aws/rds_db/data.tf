
# Look up the bastion host security group (cross-VPC, same region peering)
data "aws_security_group" "bastion" {
  name = "company-bastion-sg"
}

# Look up the backend ECS instances security group (cross-VPC, same region peering)
data "aws_security_group" "backend_ecs" {
  name = "company-backend-ecs-instances-sg-alb-to-cluster"
}
