# AWS Transit Gateway for Central Inspection VPC
# This TGW can be used to connect multiple VPCs (spoke, inspection, shared services)
# and route traffic through the inspection VPC for centralized egress/ingress filtering.

module "tgw" {
  source = "terraform-aws-modules/transit-gateway/aws"

  name        = "Central-Firewall-Inspection-tgw"
  description = "TGW Used to Route Traffic through Central Firewall"

  enable_auto_accept_shared_attachments = true

  vpc_attachments = {
    backend_vpc = {
      vpc_id                 = data.aws_vpc.backend.id
      subnet_ids             = data.aws_subnets.backend_private.ids
      dns_support            = true
      ipv6_support           = true
      appliance_mode_support = true

      # Forward all egress from backend VPC to the inspection VPC via TGW
      # Replace <inspection_vpc_attachment> with the actual key from your vpc_attachments map
      tgw_routes = [
        {
          ## Internet Bound/ Any Egress Traffic Inspection
          destination_cidr_block        = "0.0.0.0/0"
          transit_gateway_attachment_id = module.tgw.vpc_attachments["inspection"].transit_gateway_attachment_id
        },
        {
          ## Send Back Traffic to Backend VPC After Insepction. 
          destination_cidr_block        = data.aws_vpc.backend.cidr_block
          transit_gateway_attachment_id = module.tgw.vpc_attachments["backend_vpc"].transit_gateway_attachment_id
        }
      ]
    }
    inspection = {
      vpc_id                 = data.aws_vpc.inspection.id
      subnet_ids             = data.aws_subnets.inspection_private.ids
      dns_support            = true
      ipv6_support           = true
      appliance_mode_support = true
    }
  }
  /*
  ram_allow_external_principals = true
  ram_principals                = [307990089504]
	*/
  tags = {
    Name        = "central-inspection-tgw"
    Environment = "dev"
    Owner       = "Prabhmeet"
  }
}
output "tgw_id" {
  value = aws_ec2_transit_gateway.inspection.id
}
