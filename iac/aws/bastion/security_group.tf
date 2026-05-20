# Security Group for Bastion Host - Allow SSH from anywhere
resource "aws_security_group" "bastion_sg" {
  name        = "company-bastion-sg"
  description = "Allow SSH from anywhere and PostgreSQL to database"
  vpc_id      = module.bastion_vpc.vpc_id
  ## Each Port For Different Application the bastion Supports

  ## HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.employee_ips
    description = "HTTPS from Company Employees"
  }
  ## HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.employee_ips
    description = "HTTPS from Company Employees"
  }
  ## SSH into the Instance
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.employee_ips
    description = "SSH from Company Employees"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "company-bastion-sg"
    }
  )
}
