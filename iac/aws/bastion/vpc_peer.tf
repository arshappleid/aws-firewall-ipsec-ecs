# VPC Peering Connection - Bastion to Database VPC
resource "aws_vpc_peering_connection" "bastion_to_db" {
  vpc_id      = module.bastion_vpc.vpc_id
  peer_vpc_id = data.aws_vpc.rds_vpc.id
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = {
    Name = "company-bastion-to-database-peering"
  }
}

# Route from Bastion VPC to Database VPC
resource "aws_route" "bastion_to_db" {
  route_table_id            = module.bastion_vpc.public_route_table_ids[0]
  destination_cidr_block    = data.aws_vpc.rds_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.bastion_to_db.id
}

# Route from Database VPC (us-east-2a) to Bastion VPC
resource "aws_route" "db_to_bastion" {
  route_table_id            = tolist(data.aws_route_tables.db_route_table_default.ids)[0]
  destination_cidr_block    = module.bastion_vpc.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.bastion_to_db.id
}


# Security Group Rule - Allow PostgreSQL from Bastion VPC
resource "aws_security_group_rule" "db_from_bastion" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion_sg.id
  security_group_id        = data.aws_security_group.rds_sg.id
  description              = "Allow PostgreSQL from Bastion VPC"
}
