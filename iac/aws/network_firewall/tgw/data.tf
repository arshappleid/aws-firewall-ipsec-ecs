data "aws_vpc" "backend" {
  filter {
    name   = "tag:Name"
    values = ["backend-vpc"]
  }
}

data "aws_subnets" "backend_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.backend.id]
  }
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}
