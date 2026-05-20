# Source: https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/latest/submodules/cluster
module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "6.11.0"

  name = "company-backend-ecs-cluster"

  # Use autoscaling capacity providers
  autoscaling_capacity_providers = {
    on_demand = {
      auto_scaling_group_arn         = module.asg_ecs_on_demand.autoscaling_group_arn
      managed_termination_protection = "DISABLED"

      managed_scaling = {
        maximum_scaling_step_size = 10
        minimum_scaling_step_size = 1
        status                    = "DISABLED"
        target_capacity           = var.on_demand_managed_scaling.target_capacity
      }

      default_capacity_provider_strategy = {
        weight = 100 - var.cluster_config.spot_instance_percentage
        base   = 1
      }
    }

    spot = {
      auto_scaling_group_arn         = module.asg_ecs_spot.autoscaling_group_arn
      managed_termination_protection = "DISABLED"

      managed_scaling = {
        maximum_scaling_step_size = 10
        minimum_scaling_step_size = 1
        status                    = "DISABLED"
        target_capacity           = var.spot_managed_scaling.target_capacity
      }

      default_capacity_provider_strategy = {
        weight = var.cluster_config.spot_instance_percentage
      }
    }
  }

  tags = var.tags
}
