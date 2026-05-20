# ─── SIEM Logs Access (inline policy on bastion role) ─────────────────────────

resource "aws_iam_role_policy" "bastion_siem_logs" {
  name = "company-bastion-siem-logs-access"
  role = aws_iam_role.bastion.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SIEMInfraS3Read"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::aws-waf-logs-company",
          "arn:aws:s3:::aws-waf-logs-company/*",
          "arn:aws:s3:::company-central-network-firewall-logs",
          "arn:aws:s3:::company-central-network-firewall-logs/*",
          "arn:aws:s3:::company-cloudfront-logs",
          "arn:aws:s3:::company-cloudfront-logs/*",
          "arn:aws:s3:::company-cognito-user-pool-logs-156041414531-us-east-2-an",
          "arn:aws:s3:::company-cognito-user-pool-logs-156041414531-us-east-2-an/*",
          "arn:aws:s3:::company-compute-infra-metrics",
          "arn:aws:s3:::company-compute-infra-metrics/*",
          "arn:aws:s3:::prab-cognito-aws-waf-logs",
          "arn:aws:s3:::prab-cognito-aws-waf-logs/*"
        ]
      },
      {
        Sid    = "SIEMInfraS3Write"
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::company-compute-infra-metrics/*",
          "arn:aws:s3:::company-athena-results/*"
        ]
      }
    ]
  })
}
