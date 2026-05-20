
resource "aws_ec2_transit_gateway_route_table" "firewall_route_table" {
  transit_gateway_id = module.tgw.ec2_transit_gateway_id
}

resource "aws_ec2_transit_gateway_route" "firewall_route" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.tgw.ec2_transit_gateway_vpc_attachment_ids["inspection_vpc"].id
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_id
}

resource "aws_ec2_transit_gateway_route" "backend_vpc_route_table" {
  destination_cidr_block         = "10.0.0.0/16"
  transit_gateway_attachment_id  = module.tgw.ec2_transit_gateway_vpc_attachment_ids["backend_vpc"].id
  transit_gateway_route_table_id = module.tgw.ec2_transit_gateway_id
}
