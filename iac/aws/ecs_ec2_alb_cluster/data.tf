# Look up the RDS database VPC by name tag
data "aws_vpc" "rds" {
  filter {
    name   = "tag:Name"
    values = ["RDS-VPC"]
  }
}

# Look up the RDS database default route table
data "aws_route_table" "rds" {
  vpc_id = data.aws_vpc.rds.id

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

# Look up the RDS security group
data "aws_security_group" "rds" {
  name   = "company-rds-sg-2"
  vpc_id = data.aws_vpc.rds.id
}
