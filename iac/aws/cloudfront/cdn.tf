module "cdn" {
  source = "terraform-aws-modules/cloudfront/aws"

  aliases = ["chat.datecompany.com"]
  comment = "Company CloudFront"

  price_class = "PriceClass_100"
  #web_acl_id  = "8c1cb5cd-e11c-4455-98a8-3a2e27f2cd4b" ## Prabs-Custom-Waf-resource

  origin_access_control = {
    s3_oac = {
      description      = "CloudFront access to S3"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  logging_config = {
    bucket = "company-cloudfront-logs.s3.amazonaws.com"
    prefix = "logs/"
  }

  origin = {
    /*
    something = {
      domain_name = "something.example.com"
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "match-viewer"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
    */

    wss_chat = {
      domain_name = data.aws_lb.private_backend_alb.dns_name
      vpc_origin_config = {
        vpc_origin_id            = aws_cloudfront_vpc_origin.chat.id
        origin_keepalive_timeout = 60
        origin_read_timeout      = 60 # keep high for long-lived WS connections
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = "wss_chat"
    viewer_protocol_policy = "https-only"

    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD"]
    compress        = false # don't compress WebSocket frames

    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac" # AllViewerExceptHostHeader
  }
  /*
  ordered_cache_behavior = [
    {
      path_pattern           = "/static/*"
      target_origin_id       = "s3"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true
      query_string    = true
    }
  ]
  */


  viewer_certificate = {
    acm_certificate_arn = "arn:aws:acm:us-east-1:156041414531:certificate/10015ab8-6db2-434a-9ac7-2a1fe69a3ea9" // correct acm arn
    ssl_support_method  = "sni-only"
  }
}
