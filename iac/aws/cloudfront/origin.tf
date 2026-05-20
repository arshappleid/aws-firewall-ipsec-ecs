resource "aws_cloudfront_vpc_origin" "chat" {
  vpc_origin_endpoint_config {
    name                   = "chat-alb-origin"
    arn                    = data.aws_lb.private_backend_alb.arn
    http_port              = 80
    https_port             = 443
    origin_protocol_policy = "http-only"
    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }
}
