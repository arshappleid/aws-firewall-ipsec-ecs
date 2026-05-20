data "aws_ec2_transit_gateway" "central_firewall_tgw" {
  filter {
    name   = "tag:Name"
    values = ["Central-Firewall-TGW"]
  }
}

# VPC is now managed in the networking module — look it up by name tag
data "aws_vpc" "backend" {
  filter {
    name   = "tag:Name"
    values = ["backend-vpc"]
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

# Private subnets pinned to us-east-2a for ASG placement
data "aws_subnets" "private_2a" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.backend.id]
  }
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-2a"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.backend.id]
  }
  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }
}

data "aws_route_tables" "private" {
  vpc_id = data.aws_vpc.backend.id
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

data "aws_route_tables" "public" {
  vpc_id = data.aws_vpc.backend.id
  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }
}
