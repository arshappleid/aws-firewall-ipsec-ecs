data "aws_vpc" "backend" {
  filter {
    name   = "tag:Name"
    values = ["backend-vpc"]
  }
}

data "aws_subnets" "backend_private_subnet" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.backend.id]
  }
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

data "aws_networkfirewall_firewall" "central" {
  name = "prod-web-firewall-us-east-2"
}

data "aws_ec2_transit_gateway" "central" {
  filter {
    name   = "tag:Name"
    values = ["Central-Firewall-Inspection-tgw"]
  }
}
