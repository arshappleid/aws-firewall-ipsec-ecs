# Bastion EC2 Instance (Spot)
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  key_name      = "Prabhs-Key-Pair-Company"

  instance_market_options {
    market_type = "spot"
    spot_options {
      spot_instance_type             = "persistent"
      instance_interruption_behavior = "stop"
    }
  }

  subnet_id                   = module.bastion_vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.bastion.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/startup.sh", {
    rds_endpoint           = data.aws_db_instance.rds.endpoint
    grafana_db_password    = var.grafana_db_password
    grafana_admin_password = var.grafana_admin_password
    opensearch_endpoint    = data.aws_opensearch_domain.main.endpoint
    bastion_public_eip     = data.aws_eip.bastion.public_ip
    #tailscale_auth_key     = var.tailscale_auth_key
    nlb_private_ip = "192.168.1.40/32"
  })

  tags = merge(
    var.tags,
    {
      Name = "company-bastion-host-spot"
    }
  )
}


# Associate the existing EIP with the bastion instance
resource "aws_eip_association" "bastion" {
  instance_id   = aws_instance.bastion.id
  allocation_id = data.aws_eip.bastion.id
}



# Outputs
output "bastion_public_ip" {
  description = "Elastic IP of bastion host"
  value       = data.aws_eip.bastion.public_ip
}

output "database_connection_from_bastion" {
  description = "Command to connect to database from bastion"
  value       = "psql -h ${data.aws_db_instance.rds.address} -U company_admin -d companydb"
}
