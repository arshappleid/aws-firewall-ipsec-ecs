module "tgw" {
  source = "terraform-aws-modules/transit-gateway/aws"

  name        = "Central-Firewall-TGW"
  description = "TGW Connected to Central Firewall"

  enable_auto_accept_shared_attachments = true

  vpc_attachments = {
    backend_vpc = {
      vpc_id                                          = data.aws_vpc.backend.id
      subnet_ids                                      = data.aws_vpc.backend.private_subnet
      dns_support                                     = true
      ipv6_support                                    = false
      appliance_mode_support                          = true
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
    }

    inspection_vpc = {
      vpc_id                                          = data.aws_vpc.inspection.id
      subnet_ids                                      = data.aws_vpc.inspection.tgw_subnet
      dns_support                                     = true
      ipv6_support                                    = false
      appliance_mode_support                          = true
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
    }
  }
  create_tgw_routes             = false ## Create the Route Tables on your OWN
  ram_allow_external_principals = true
  ram_principals                = [307990089504]

  tags = {
    Owner       = "Prabhmeet"
    Environment = "dev"
  }
}
## Disable default route table
resource "aws_ec2_transit_gateway" "this" {
  description                     = "TGW with no default route table"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
}
