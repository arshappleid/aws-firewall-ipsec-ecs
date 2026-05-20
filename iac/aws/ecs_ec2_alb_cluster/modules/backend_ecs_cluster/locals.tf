locals {
  ecs_cluster_name = "${var.project_name}-ecs-cluster"

  # Calculate capacity provider weights based on spot_instance_percentage
  # Formula: if spot is 50%, then on_demand:spot ratio should be 1:1
  # if spot is 75%, then on_demand:spot ratio should be 1:3 (25% on_demand, 75% spot)
  spot_percentage  = var.cluster_config.spot_instance_percentage
  on_demand_weight = 100 - local.spot_percentage
  spot_weight      = local.spot_percentage
  on_demand_base   = 1 # Always keep at least 1 on-demand instance for stability
}
