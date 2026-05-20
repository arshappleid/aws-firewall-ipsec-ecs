locals {
  cluster_configs = {
    "ai-cluster" = {
      # The Spot Service to watch
      primary_spot_arn = "arn:aws:ecs:us-east-2:156041414531:service/AI-Service-ecs-cluster/ai-spot"
      # The specific Lambda for this cluster
      lambda_arn  = "arn:aws:lambda:us-east-2:156041414531:function:AI-Fargate-Spot-Fallback"
      lambda_name = "AI-Fargate-Spot-Fallback"
    }

    "chat-cluster" = {
      primary_spot_arn = "arn:aws:ecs:us-east-2:156041414531:service/Chat-WSS-ecs-cluster/chat-wss-spot"
      lambda_arn       = "arn:aws:lambda:us-east-2:156041414531:function:Chat-Fargate-Spot-Fallback"
      lambda_name      = "Chat-Fargate-Spot-Fallback"
    }

  }
}

# 1. Create the EventBridge Rule for each cluster
resource "aws_cloudwatch_event_rule" "spot_fallback_rule" {
  for_each = local.cluster_configs

  name        = "${each.key}-spot-failure-rule"
  description = "Trigger fallback for ${each.key}"

  event_pattern = jsonencode({
    source      = ["aws.ecs"],
    detail-type = ["ECS Service Action"],
    resources   = [each.value.primary_spot_arn],
    detail = {
      eventName = ["SERVICE_TASK_PLACEMENT_FAILURE", "SERVICE_STEADY_STATE"]
    }
  })
}

# 2. Link each Rule to its specific Lambda
resource "aws_cloudwatch_event_target" "lambda_target" {
  for_each = local.cluster_configs

  rule      = aws_cloudwatch_event_rule.spot_fallback_rule[each.key].name
  target_id = "SendToLambda"
  arn       = each.value.lambda_arn
}

# 3. Grant Permission for EventBridge to invoke each specific Lambda
resource "aws_lambda_permission" "allow_cloudwatch" {
  for_each = local.cluster_configs

  statement_id  = "AllowExecutionFromCloudWatch-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.spot_fallback_rule[each.key].arn
}
