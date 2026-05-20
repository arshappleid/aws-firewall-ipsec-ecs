# ─── Bastion IAM Role ─────────────────────────────────────────────────────────

resource "aws_iam_role" "bastion" {
  name = "company-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "company-bastion-role"
    }
  )
}

# ─── Instance Profile ─────────────────────────────────────────────────────────

resource "aws_iam_instance_profile" "bastion" {
  name = "company-bastion-instance-profile"
  role = aws_iam_role.bastion.name
}

# ─── SSM Managed Policy (for remote session access) ──────────────────────────

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ─── Route 53 Policy (for Certbot DNS-01 validation) ─────────────────────────

resource "aws_iam_policy" "bastion_route53" {
  name        = "company-bastion-route53"
  description = "Allow bastion to manage Route 53 records for Certbot DNS validation"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:GetChange"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_route53" {
  role       = aws_iam_role.bastion.name
  policy_arn = aws_iam_policy.bastion_route53.arn
}

# ─── Athena & Glue Policy ────────────────────────────────────────────────────

resource "aws_iam_policy" "bastion_athena_glue" {
  name        = "company-bastion-athena-glue"
  description = "Allow bastion to query Athena, read Glue catalog, and access Athena S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AthenaFullAccess"
        Effect   = "Allow"
        Action   = "athena:*"
        Resource = "*"
      },
      {
        Sid    = "GlueCatalogReadAccess"
        Effect = "Allow"
        Action = [
          "glue:GetDatabases",
          "glue:GetDatabase",
          "glue:GetTables",
          "glue:GetTable",
          "glue:GetPartitions",
          "glue:GetPartition"
        ]
        Resource = "*"
      },
      {
        "Sid" : "S3ReadLogBuckets",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::aws-waf-logs-company",
          "arn:aws:s3:::aws-waf-logs-company/*",
          "arn:aws:s3:::company-central-network-firewall-logs",
          "arn:aws:s3:::company-central-network-firewall-logs/*",
          "arn:aws:s3:::alb-logs-company", "arn:aws:s3:::alb-logs-company/*",
          "arn:aws:s3:::company-cloudfront-logs", "arn:aws:s3:::company-cloudfront-logs/*"

        ]
      },
      {
        "Sid" : "S3AthenaResults",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::company-athena-results",
          "arn:aws:s3:::company-athena-results/*",
          "arn:aws:s3:::company-athena-queries",
          "arn:aws:s3:::company-athena-queries/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_athena_glue" {
  role       = aws_iam_role.bastion.name
  policy_arn = aws_iam_policy.bastion_athena_glue.arn
}

# ─── CloudWatch Logs Policy ──────────────────────────────────────────────────

resource "aws_iam_role_policy_attachment" "bastion_cloudwatch" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
output "bastion_iam_role_arn" {
  description = "ARN of the bastion IAM role"
  value       = aws_iam_role.bastion.arn
}
