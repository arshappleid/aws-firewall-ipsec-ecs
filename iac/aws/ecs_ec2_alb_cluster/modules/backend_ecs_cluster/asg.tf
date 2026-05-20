# On-Demand ASG for ECS
module "asg_ecs_on_demand" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "9.1.0"

  name = "${var.project_name}-ecs-on-demand"

  min_size                  = var.cluster_config.on_demand_min_size
  max_size                  = var.cluster_config.on_demand_max_size
  desired_capacity          = var.cluster_config.on_demand_desired_capacity
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  health_check_grace_period = var.cluster_config.health_check_grace_period
  vpc_zone_identifier       = data.aws_subnets.private_2a.ids # pinned to us-east-2a

  # Launch template
  launch_template_name        = "${var.project_name}-ecs-on-demand-lt"
  launch_template_description = "ECS on-demand instances launch template"
  update_default_version      = true

  # ECS-optimized AMI
  image_id          = data.aws_ami.ecs_optimized.id
  instance_type     = var.cluster_config.ecs_instance_type_on_demand
  ebs_optimized     = true
  enable_monitoring = var.cluster_config.enable_monitoring

  # User data to register with ECS cluster
  user_data = base64encode(templatefile("${path.module}/user_data_ecs.sh", {
    cluster_name = "${var.project_name}-ecs-cluster"
  }))

  # IAM role & instance profile
  create_iam_instance_profile = false
  iam_instance_profile_arn    = aws_iam_instance_profile.backend_ec2_profile.arn

  # Protect from scale-in by ECS
  protect_from_scale_in = false

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = var.cluster_config.ebs_volume_size
        volume_type           = var.cluster_config.on_demand_volume_type
      }
    }
  ]

  credit_specification = {
    cpu_credits = "standard"
  }

  # This will ensure imdsv2 is enabled, required, and a single hop which is aws security
  # best practices
  # See https://docs.aws.amazon.com/securityhub/latest/userguide/autoscaling-controls.html#autoscaling-4
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 5
  }

  network_interfaces = [
    {
      delete_on_termination       = true
      description                 = "eth0"
      device_index                = 0
      security_groups             = [aws_security_group.backend_sg.id]
      associate_public_ip_address = false
    }
  ]

  tag_specifications = [
    {
      resource_type = "instance"
      tags = merge(var.tags, {
        Name         = "${var.project_name}-ecs-on-demand"
        AmidroneType = "ecs-container-instance"
      })
    },
    {
      resource_type = "volume"
      tags          = merge(var.tags, { Name = "${var.project_name}-ecs-volume" })
    }
  ]

  tags = var.tags
}

# Spot ASG for ECS
module "asg_ecs_spot" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "9.1.0"

  name = "${var.project_name}-ecs-spot"

  min_size                  = var.cluster_config.spot_min_size
  max_size                  = var.cluster_config.spot_max_size
  desired_capacity          = var.cluster_config.spot_desired_capacity
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  health_check_grace_period = var.cluster_config.health_check_grace_period
  vpc_zone_identifier       = data.aws_subnets.private_2a.ids # pinned to us-east-2a

  # Launch template
  launch_template_name        = "${var.project_name}-ecs-spot-lt"
  launch_template_description = "ECS spot instances launch template"
  update_default_version      = true

  # ECS-optimized AMI
  image_id          = data.aws_ami.ecs_optimized.id
  ebs_optimized     = true
  enable_monitoring = var.cluster_config.enable_monitoring

  # User data to register with ECS cluster
  user_data = base64encode(templatefile("${path.module}/user_data_ecs.sh", {
    cluster_name = "${var.project_name}-ecs-cluster"
  }))

  # IAM role & instance profile
  create_iam_instance_profile = false
  iam_instance_profile_arn    = aws_iam_instance_profile.backend_ec2_profile.arn

  # Mixed instances for spot diversity
  use_mixed_instances_policy = true
  mixed_instances_policy = {
    instances_distribution = {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "price-capacity-optimized"
    }

    launch_template = {
      launch_template_specification = {
        launch_template_id = null # Module manages this
      }

      override = [
        for instance_type in var.cluster_config.ecs_instance_types_spot : {
          instance_type     = instance_type
          weighted_capacity = "1"
        }
      ]
    }
  }

  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = var.cluster_config.ebs_volume_size
        volume_type           = var.cluster_config.spot_volume_type
      }
    }
  ]

  # Protect from scale-in by ECS
  protect_from_scale_in = false

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 5
  }

  network_interfaces = [
    {
      delete_on_termination       = true
      description                 = "eth0"
      device_index                = 0
      security_groups             = [aws_security_group.backend_sg.id]
      associate_public_ip_address = false
    }
  ]

  tag_specifications = [
    {
      resource_type = "instance"
      tags = merge(var.tags, {
        Name         = "${var.project_name}-ecs-spot"
        AmidroneType = "ecs-container-instance"
      })
    },
    {
      resource_type = "volume"
      tags          = merge(var.tags, { Name = "${var.project_name}-ecs-volume" })
    },
    {
      resource_type = "spot-instances-request"
      tags          = merge(var.tags, { Name = "${var.project_name}-ecs-spot-request" })
    }
  ]

  tags = var.tags
}
