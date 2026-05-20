
resource "aws_route" "fw_subnet_default" {
  route_table_id         = module.inspection_vpc.private_route_table_ids[1]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = ## Nat Gateway ID 
}


resource "aws_route" "fw_subnet_rfc1918_10" {
  route_table_id         = module.inspection_vpc.private_route_table_ids[1]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = data.aws_ec2_transit_gateway.central.id
}


resource "aws_route" "fw_subnet_rfc1918_172" {
  route_table_id         = module.inspection_vpc.private_route_table_ids[1]
  destination_cidr_block = "172.16.0.0/12"
  transit_gateway_id     = data.aws_ec2_transit_gateway.central.id
}


resource "aws_route" "fw_subnet_rfc1918_192" {
  route_table_id         = module.inspection_vpc.private_route_table_ids[1]
  destination_cidr_block = "192.168.0.0/16"
  transit_gateway_id     = data.aws_ec2_transit_gateway.central.id
}
