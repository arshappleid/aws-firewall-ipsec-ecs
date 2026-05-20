module "nlb" {
  source = "terraform-aws-modules/alb/aws"

  name               = "Central-Inspection-NLB"
  load_balancer_type = "network"
  vpc_id             = data.aws_vpc.inspection.id
  subnets            = [data.aws_subnet.public_nlb_subnet.id]

  # Security Group
  enforce_security_group_inbound_rules_on_private_link_traffic = "on"
  security_group_ingress_rules = {
    cloudfront_all_tcp = {
      from_port      = 0
      to_port        = 65535
      ip_protocol    = "tcp"
      description    = "Allow all TCP from CloudFront origin-facing IPv4 prefix list"
      prefix_list_id = data.aws_ec2_managed_prefix_list.cloudfront_ipv4.id
    }
    cloudfront_all_udp = {
      from_port      = 0
      to_port        = 65535
      ip_protocol    = "udp"
      description    = "Allow all UDP from CloudFront origin-facing IPv4 prefix list"
      prefix_list_id = data.aws_ec2_managed_prefix_list.cloudfront_ipv4.id
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  /*
  access_logs = {
    bucket = "my-nlb-logs"
  }

  */

  listeners = {
    http = {
      port            = 443
      protocol        = "TLS"
      certificate_arn = data.aws_acm_certificate.datecompany_wildcard.arn
      forward = {
        target_group_key = "api_gw_http"
      }
    }

    websocket = {
      port            = 1024
      protocol        = "TLS"
      certificate_arn = data.aws_acm_certificate.datecompany_wildcard.arn
      forward = {
        target_group_key = "websocket"
      }
    }

    webrtc = {
      port            = 1025
      protocol        = "TLS"
      certificate_arn = data.aws_acm_certificate.datecompany_wildcard.arn
      forward = {
        target_group_key = "webrtc"
      }
    }
  }

  target_groups = {
    api_gw_http = {
      protocol    = "TLS" ## Private Link API GW Endpoint
      port        = 80
      target_type = "ip"
      target_id   = "10.0.1.194" ## Static IP of the API Gateway Endpoint
    }
    websocket = {
      protocol    = "TCP"
      port        = 80 ## Websocket also goes over port 80
      target_type = "ip"
      target_id   = "10.0.1.115" ## Static IP of the API Gateway Endpoint
    }
    webrtc = {
      protocol    = "TCP"
      port        = 80
      target_type = "ip"
      target_id   = "10.0.47.1" ## Static IP of the API Gateway Endpoint
    }
  }

  tags = {
    Environment = "prod"
    Owener      = "Prabhmeet"
  }
}
