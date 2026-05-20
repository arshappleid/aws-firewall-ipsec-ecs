# ── Passkey Service IAM Roles ─────────────────────────────────────────────────

# Task Execution Role — used by ECS to pull the passkey image, write logs, and fetch secrets from SSM
resource "aws_iam_role" "ecs_passkey_task_execution_role" {
  name = "passkey-ecs-task-execution-role"

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

  tags = {
    Application = "Backend"
    Environment = "Production"
    Owner       = "Prabhmeet"
    Service     = "Passkey"
  }
}

# Inline policy: ECR image pull access
resource "aws_iam_role_policy" "passkey_execution_ecr" {
  name = "passkey-ecr-access"
  role = aws_iam_role.ecs_passkey_task_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAccess"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# Inline policy: CloudWatch Logs for the passkey log group
resource "aws_iam_role_policy" "passkey_execution_cloudwatch_logs" {
  name = "passkey-cloudwatch-logs"
  role = aws_iam_role.ecs_passkey_task_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:us-east-2:156041414531:log-group:/ApplicationLogs/backend/passkey:*"
      }
    ]
  })
}

# Inline policy: SSM Parameter Store secrets for the passkey service
resource "aws_iam_role_policy" "passkey_execution_ssm" {
  name = "passkey-ssm-secrets"
  role = aws_iam_role.ecs_passkey_task_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMSecrets"
        Effect = "Allow"
        Action = "ssm:GetParameters"
        Resource = [
          "arn:aws:ssm:us-east-2:156041414531:parameter/company/prod/passkey/*",
          "arn:aws:ssm:us-east-2:156041414531:parameter/company/api_docs/password"
        ]
      }
    ]
  })
}

# ─────────────────────────────────────────────────────────────────────────────

# Task Role — used by the passkey container at runtime for Cognito operations
resource "aws_iam_role" "ecs_passkey_task_role" {
  name = "passkey-ecs-task-role"

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

  tags = {
    Application = "Backend"
    Environment = "Production"
    Owner       = "Prabhmeet"
    Service     = "Passkey"
  }
}

# Inline policy: Cognito operations required by the passkey service
resource "aws_iam_role_policy" "passkey_task_cognito" {
  name = "passkey-cognito-ops"
  role = aws_iam_role.ecs_passkey_task_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CognitoPasskeyOps"
        Effect = "Allow"
        Action = [
          "cognito-idp:SignUp",
          "cognito-idp:AdminUpdateUserAttributes",
          "cognito-idp:AdminGetUser",
          "cognito-idp:AdminUserGlobalSignOut"
        ]
        # Replace <COGNITO_USER_POOL_ID> with the actual Cognito User Pool ID
        Resource = "arn:aws:cognito-idp:us-east-1:156041414531:userpool/us-east-1_72AFNcqQx"
      }
    ]
  })
}
