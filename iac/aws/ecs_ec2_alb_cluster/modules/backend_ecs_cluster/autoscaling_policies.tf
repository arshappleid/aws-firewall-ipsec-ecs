/* Commented Out to Save Cost
# Target Tracking Scaling Policy for On-Demand ASG
resource "aws_autoscaling_policy" "on_demand_cpu_tracking" {
  name                   = "${var.project_name}-on-demand-cpu-tracking"
  autoscaling_group_name = module.asg_ecs_on_demand.autoscaling_group_name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.scale_up_cpu_threshold
  }
}

# Target Tracking Scaling Policy for Spot ASG
resource "aws_autoscaling_policy" "spot_cpu_tracking" {
  name                   = "${var.project_name}-spot-cpu-tracking"
  autoscaling_group_name = module.asg_ecs_spot.autoscaling_group_name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.scale_up_cpu_threshold
  }
}
*/
