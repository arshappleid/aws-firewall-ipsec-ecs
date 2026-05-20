# IAM Role for EC2 instances running ECS tasks - Correct Config ensures binding to cluster
resource "aws_iam_role" "backend_ec2_role" {
  name = "${var.project_name}-ecs-ec2-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Sid    = "AllowEc2ToAssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-ec2-role"
  })
}

# Attach ECS permissions (required for ECS agent to register with cluster)
resource "aws_iam_role_policy_attachment" "backend_ec2_ecs" {
  role       = aws_iam_role.backend_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Attach CloudWatch permissions (for logging)
resource "aws_iam_role_policy_attachment" "backend_ec2_cloudwatch" {
  role       = aws_iam_role.backend_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach SSM permissions (for debugging via Session Manager)
resource "aws_iam_role_policy_attachment" "backend_ec2_ssm" {
  role       = aws_iam_role.backend_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach ECR permissions (for pulling container images)
resource "aws_iam_role_policy_attachment" "backend_ec2_ecr" {
  role       = aws_iam_role.backend_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Instance Profile (wrapper for the role)
resource "aws_iam_instance_profile" "backend_ec2_profile" {
  name = "FlaskAPIEC2Profile"
  role = aws_iam_role.backend_ec2_role.name

  tags = merge(var.tags, {
    Name = "${var.project_name}-ec2-profile"
  })
}

# IAM Role for ECS Task Execution (used by ECS to pull images, logs, and env files)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Sid    = "AllowEcsTasksToAssumeRole"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-ecs-task-execution-role"
  })
}

# Custom policy for S3 access to environment variables
resource "aws_iam_policy" "ecs_s3_env" {
  name        = "${var.project_name}-ecs-s3-env-policy"
  description = "Allow ECS task execution to pull environment variables from S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::company-application-artifacts/backend/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::company-application-artifacts"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::company-profile-pictures"
        ]
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-s3-env-policy"
  })
}

# Attach custom S3 policy to task execution role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_s3_env" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_s3_env.arn
}

# Attach standard ECS task execution policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Custom policy for CloudWatch Logs access
resource "aws_iam_policy" "ecs_cloudwatch_logs" {
  name        = "${var.project_name}-ecs-cloudwatch-logs-policy"
  description = "Allow Backend to store application logs in CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:us-east-2:156041414531:log-group:/flutter-app/logs:*",
          "arn:aws:logs:us-east-2:156041414531:log-group:/ApplicationLogs/backend/flask-api:*"
        ]
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-cloudwatch-logs-policy"
  })
}

# Attach CloudWatch Logs policy to task execution role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_cloudwatch_logs" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_cloudwatch_logs.arn
}

# Custom policy for fetching Datadog API key from SSM Parameter Store
resource "aws_iam_policy" "ecs_task_execution_ssm_datadog" {
  name        = "${var.project_name}-ecs-task-execution-ssm-datadog"
  description = "Allow ECS task execution role to fetch Datadog API key from SSM Parameter Store"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:ssm:*:*:parameter/datadog/api_key",
          "arn:aws:ssm:us-east-2:156041414531:parameter/company/public/datadog/apikey"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.*.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-ssm-datadog-policy"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_ssm_datadog" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_ssm_datadog.arn
}

# Custom policy for fetching all company/prod/* params from SSM Parameter Store
resource "aws_iam_policy" "ecs_task_execution_ssm_prod_params" {
  name        = "${var.project_name}-ecs-task-execution-ssm-prod-params"
  description = "Allow ECS task execution role to fetch all company/prod/* parameters from SSM Parameter Store"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:us-east-2:156041414531:parameter/company/prod/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.us-east-2.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-ssm-prod-params-policy"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_ssm_prod_params" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_ssm_prod_params.arn
}

# IAM Role for ECS Tasks (used by containers at runtime)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Sid    = "AllowEcsTasksToAssumeRole"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-ecs-task-role"
  })
}


# Custom policy for SSM Parameter Store access to database credentials
resource "aws_iam_policy" "access_profile_pictures_s3_buckets" {
  name        = "${var.project_name}-read_update_user_profile_pictures"
  description = "Allow ECS tasks to read database credentials from SSM Parameter Store"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::company-profile-pictures",
          "arn:aws:s3:::company-profile-pictures/*"
        ]
      },
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-allow access to profile pictures s3 bucket"
  })
}

# Attach AWS managed policies to task role
resource "aws_iam_role_policy_attachment" "ecs_task_profile_picture_access_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = resource.aws_iam_policy.access_profile_pictures_s3_buckets.arn
}


# Attach AWS managed policies to task role
resource "aws_iam_role_policy_attachment" "ecs_task_dynamodb" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_task_ecs_role" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_task_s3_readonly" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Custom policy for SSM Parameter Store access to database credentials
resource "aws_iam_policy" "ecs_task_ssm_db_params" {
  name        = "${var.project_name}-ecs-task-ssm-db-params"
  description = "Allow ECS tasks to read database credentials from SSM Parameter Store"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:*:*:parameter/company/sqldatabase/*",
          "arn:aws:ssm:*:*:parameter/company/ai/*",
          "arn:aws:ssm:*:*:parameter/company/public/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.*.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-ssm-db-params-policy"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_ssm_db_params" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_ssm_db_params.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_ssm_readonly" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# Custom policy to allow SSM ECS Exec
resource "aws_iam_policy" "ssm_ecs_exec" {
  name        = "${var.project_name}-permission-to-allow-ssm-ecs-exec"
  description = "Permission to allow SSM ECS Exec"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-ssm-ecs-exec-policy"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_ssm_ecs_exec" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ssm_ecs_exec.arn
}

# Custom policy for SNS push notification registration (/notifications/register)
# Fixes: AuthorizationError when calling the CreatePlatformEndpoint operation
resource "aws_iam_policy" "ecs_task_sns_push_notifications" {
  name        = "${var.project_name}-ecs-task-sns-push-notifications"
  description = "Allow ECS tasks to register device endpoints with SNS for push notifications"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SNSCreatePlatformEndpoint"
        Effect = "Allow"
        Action = [
          "sns:CreatePlatformEndpoint",
          "sns:DeleteEndpoint",
          "sns:GetEndpointAttributes",
          "sns:SetEndpointAttributes"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-sns-push-notifications-policy"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_sns_push_notifications" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_sns_push_notifications.arn
}

# ── Datadog Agent IAM Roles ───────────────────────────────────────────────────

# Task Execution Role — used by ECS to pull the Datadog image and fetch the API key from SSM
resource "aws_iam_role" "ecs_datadog_task_execution_role" {
  name = "${var.project_name}-ecs-datadog-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Sid    = "AllowEcsTasksToAssumeRole"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-ecs-datadog-task-execution-role"
  })
}

# Attach the AWS managed ECS task execution policy (ECR pull + CloudWatch logs)
resource "aws_iam_role_policy_attachment" "datadog_execution_managed" {
  role       = aws_iam_role.ecs_datadog_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Inline policy: fetch Datadog API key from SSM
resource "aws_iam_role_policy" "datadog_execution_ssm" {
  name = "datadog-ssm-api-key"
  role = aws_iam_role.ecs_datadog_task_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:ssm:us-east-2:156041414531:parameter/datadog/api_key",
          "arn:aws:ssm:us-east-2:156041414531:parameter/company/public/datadog/apikey"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.us-east-2.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Task Role — used by the Datadog agent container at runtime to collect ECS/EC2 metrics
resource "aws_iam_role" "ecs_datadog_task_role" {
  name = "${var.project_name}-ecs-datadog-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Sid    = "AllowEcsTasksToAssumeRole"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-ecs-datadog-task-role"
  })
}

# Inline policy: permissions the Datadog agent needs to scrape ECS/EC2/CloudWatch metrics
resource "aws_iam_role_policy" "datadog_task_permissions" {
  name = "datadog-agent-permissions"
  role = aws_iam_role.ecs_datadog_task_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECSMetrics"
        Effect = "Allow"
        Action = [
          "ecs:ListClusters",
          "ecs:ListContainerInstances",
          "ecs:ListServices",
          "ecs:ListTasks",
          "ecs:DescribeClusters",
          "ecs:DescribeContainerInstances",
          "ecs:DescribeServices",
          "ecs:DescribeTasks",
          "ecs:DescribeTaskDefinition"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2Metrics"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData"
        ]
        Resource = "*"
      },
      {
        Sid    = "LogsWrite"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}
