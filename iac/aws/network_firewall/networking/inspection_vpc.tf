
module "inspection_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name = "Central-Firewall-Inspection-VPC"
  cidr = "192.168.1.0/26"
  azs  = ["us-east-2a"]

  public_subnets  = ["192.168.1.32/28"]                   # Public Firewall Inspection Subnet
  private_subnets = ["192.168.1.0/28", "192.168.1.16/28"] # [Inspection subnet, Endpoint subnet]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Environment = "dev"
    Owner       = "Prabhmeet"
  }

  public_subnet_names = ["NLB-NAT-IGW-Subnet"]

  private_subnet_names = [
    "TGW-Subnet",
    "FW-Subnet",
  ]

}

