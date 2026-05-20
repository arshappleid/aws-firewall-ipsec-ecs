# VPC Peering Connection between ECS Cluster VPC and Database VPC
resource "aws_vpc_peering_connection" "ecs_to_db" {
  vpc_id      = module.ecs_cluster.vpc_id
  peer_vpc_id = data.aws_vpc.rds.id
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = merge(
    var.tags,
    {
      Name = "company-ecs-to-db-peering"
    }
  )
}

# Route from ECS VPC private subnets to Database VPC
resource "aws_route" "ecs_to_db" {
  count = length(module.ecs_cluster.private_route_table_ids)

  route_table_id            = module.ecs_cluster.private_route_table_ids[count.index]
  destination_cidr_block    = data.aws_vpc.rds.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.ecs_to_db.id
}

# Route from Database VPC to ECS VPC
resource "aws_route" "db_to_ecs" {
  route_table_id            = data.aws_route_table.rds.id
  destination_cidr_block    = module.ecs_cluster.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.ecs_to_db.id
}

# Update Database Security Group to allow traffic from ECS VPC
resource "aws_security_group_rule" "db_from_ecs" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.ecs_cluster.backend_security_group_id
  security_group_id        = data.aws_security_group.rds.id
  description              = "Allow PostgreSQL access from Backend ECS CLUSTER VPC"
}
