# Bastion Host VPC - for SSH access to database
module "bastion_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.17.0"

  name = "RDS-Bastion-Grafana-Server"
  cidr = "10.2.0.0/16"

  azs            = ["us-east-2a"]
  public_subnets = ["10.2.1.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true


  tags = var.tags
}
