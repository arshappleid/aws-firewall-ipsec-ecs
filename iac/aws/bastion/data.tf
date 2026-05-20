
# Look up the RDS database VPC
data "aws_vpc" "rds_vpc" {
  filter {
    name   = "tag:Name"
    values = ["RDS-VPC"]
  }
}

# Look up the deployed RDS instance
data "aws_db_instance" "rds" {
  db_instance_identifier = "companypostgres"
}

# Look up the RDS security group
data "aws_security_group" "rds_sg" {
  vpc_id = data.aws_vpc.rds_vpc.id

  filter {
    name   = "group-name"
    values = ["company-rds-sg-2"]
  }
}

# Look up database route tables in the RDS VPC
data "aws_route_tables" "db_route_table_default" {
  vpc_id = data.aws_vpc.rds_vpc.id

  filter {
    name   = "tag:Name"
    values = ["companypostgres-database-vpc-default"]
  }
}


# Look up the existing Elastic IP by tag — managed outside Terraform
data "aws_eip" "bastion" {
  filter {
    name   = "tag:Name"
    values = ["company-bastion-eip"]
  }
}
# Look up the OpenSearch domain
data "aws_opensearch_domain" "main" {
  domain_name = "company-opensearch-v1"
}

# Get latest Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's official AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
