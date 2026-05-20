data "aws_vpc" "backend" {
  filter {
    name   = "tag:Name"
    values = ["backend-vpc"]
  }
}

data "aws_vpc" "inspection" {
  filter {
    name   = "tag:Name"
    values = ["*-Inspection-VPC"]
  }
}
