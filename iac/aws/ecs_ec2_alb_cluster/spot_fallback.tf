# ─── Spot → On-Demand Fallback via Step Functions ─────────────────────────────
# When spot instances are interrupted or the spot ASG drops to 0 healthy instances,
# EventBridge triggers a Step Function that:
#   1. Scales up the on-demand ASG to 1
#   2. Waits for the instance to register with ECS
#   3. Polls until the spot ASG recovers
#   4. Scales the on-demand ASG back to 0

locals {
  on_demand_asg_name = module.ecs_cluster.on_demand_asg_name
  spot_asg_name      = module.ecs_cluster.spot_asg_name
  sfn_name           = "${var.project_name}-spot-fallback"
}

# ─── IAM Role for Step Functions ──────────────────────────────────────────────
resource "aws_iam_role" "spot_fallback_sfn" {
  name = "${var.project_name}-spot-fallback-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "spot_fallback_sfn" {
  name = "spot-fallback-permissions"
  role = aws_iam_role.spot_fallback_sfn.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AutoScaling"
        Effect = "Allow"
        Action = [
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:DescribeAutoScalingGroups"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# ─── Step Function State Machine ──────────────────────────────────────────────
resource "aws_sfn_state_machine" "spot_fallback" {
  name     = local.sfn_name
  role_arn = aws_iam_role.spot_fallback_sfn.arn

  definition = jsonencode({
    Comment = "Scale up on-demand ASG when spot is interrupted, scale back down when spot recovers"
    StartAt = "ScaleUpOnDemand"

    States = {
      # Step 1: Set on-demand ASG desired capacity to 1
      ScaleUpOnDemand = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:autoscaling:updateAutoScalingGroup"
        Parameters = {
          AutoScalingGroupName = local.on_demand_asg_name
          MinSize              = 1
          DesiredCapacity      = 1
        }
        ResultPath = null
        Next       = "WaitForOnDemandBoot"
      }

      # Step 2: Wait for the on-demand instance to boot and register with ECS
      WaitForOnDemandBoot = {
        Type    = "Wait"
        Seconds = 180
        Next    = "CheckSpotRecovery"
      }

      # Step 3: Check if the spot ASG has healthy instances again
      CheckSpotRecovery = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:autoscaling:describeAutoScalingGroups"
        Parameters = {
          AutoScalingGroupNames = [local.spot_asg_name]
        }
        ResultPath = "$.spotAsg"
        Next       = "EvaluateSpotHealth"
      }

      # Step 4: Evaluate whether spot has recovered
      EvaluateSpotHealth = {
        Type = "Choice"
        Choices = [
          {
            # If spot ASG has at least 1 InService instance → scale down on-demand
            Variable     = "$.spotAsg.AutoScalingGroups[0].Instances[0].LifecycleState"
            StringEquals = "InService"
            Next         = "WaitBeforeScaleDown"
          }
        ]
        Default = "WaitAndRetrySpotCheck"
      }

      # If spot hasn't recovered, wait 2 minutes and check again
      WaitAndRetrySpotCheck = {
        Type    = "Wait"
        Seconds = 120
        Next    = "CheckSpotRecovery"
      }

      # Step 5: Spot recovered — wait a cooldown before scaling down on-demand
      WaitBeforeScaleDown = {
        Type    = "Wait"
        Seconds = 300
        Comment = "5-minute cooldown to ensure spot is stable before removing on-demand"
        Next    = "ScaleDownOnDemand"
      }

      # Step 6: Scale on-demand back to 0
      ScaleDownOnDemand = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:autoscaling:updateAutoScalingGroup"
        Parameters = {
          AutoScalingGroupName = local.on_demand_asg_name
          MinSize              = 0
          DesiredCapacity      = 0
        }
        ResultPath = null
        Next       = "Done"
      }

      Done = {
        Type = "Succeed"
      }
    }
  })

  tags = var.tags
}

# ─── IAM Role for EventBridge to invoke Step Functions ────────────────────────
resource "aws_iam_role" "spot_fallback_eventbridge" {
  name = "${var.project_name}-spot-fallback-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "spot_fallback_eventbridge" {
  name = "invoke-step-function"
  role = aws_iam_role.spot_fallback_eventbridge.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "states:StartExecution"
      Resource = aws_sfn_state_machine.spot_fallback.arn
    }]
  })
}

# ─── EventBridge Rule 1: EC2 Spot Interruption Warning ────────────────────────
# Fires 2 minutes before AWS reclaims the spot instance
resource "aws_cloudwatch_event_rule" "spot_interruption" {
  name        = "${var.project_name}-spot-interruption"
  description = "Triggers on-demand fallback when a spot instance receives an interruption warning"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "spot_interruption_sfn" {
  rule     = aws_cloudwatch_event_rule.spot_interruption.name
  arn      = aws_sfn_state_machine.spot_fallback.arn
  role_arn = aws_iam_role.spot_fallback_eventbridge.arn
}

# ─── EventBridge Rule 2: Spot ASG drops to 0 instances ───────────────────────
# Catches cases where spot fails to launch (InsufficientInstanceCapacity) rather than interruption
resource "aws_cloudwatch_event_rule" "spot_asg_empty" {
  name        = "${var.project_name}-spot-asg-empty"
  description = "Triggers on-demand fallback when spot ASG has no running instances"

  event_pattern = jsonencode({
    source      = ["aws.autoscaling"]
    detail-type = ["EC2 Instance Terminate Successful"]
    detail = {
      AutoScalingGroupName = [local.spot_asg_name]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "spot_asg_empty_sfn" {
  rule     = aws_cloudwatch_event_rule.spot_asg_empty.name
  arn      = aws_sfn_state_machine.spot_fallback.arn
  role_arn = aws_iam_role.spot_fallback_eventbridge.arn
}
