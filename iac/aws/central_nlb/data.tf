data "aws_vpc" "inspection" {
  filter {
    name   = "tag:Name"
    values = ["Central-Firewall-Inspection-VPC"]
  }
}
data "aws_subnet" "public_nlb_subnet" {
  filter {
    name   = "tag:Name"
    values = ["Public-NLB-Subnet"]
  }
}

data "aws_ec2_managed_prefix_list" "cloudfront_ipv4" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

data "aws_acm_certificate" "datecompany_wildcard" {
  domain      = "*.datecompany.com"
  statuses    = ["ISSUED"]
  most_recent = true
}
