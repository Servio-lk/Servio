# Look up the default VPC in the region
data "aws_vpc" "default" {
  default = true
}

# Look up default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group for Servio EC2 Host
resource "aws_security_group" "servio_sg" {
  name        = "servio-sg"
  description = "Servio Web and Backend Security Group"
  vpc_id      = data.aws_vpc.default.id

  # Port 22: SSH (Secured by CIDR)
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  # Port 80: Customer Web Portal
  ingress {
    description = "Customer Web Portal (HTTP)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Port 443: HTTPS (for Caddy or Certbot SSL)
  ingress {
    description = "HTTPS secure web traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Port 8081: Admin Portal (Restricted to Admin IP)
  ingress {
    description = "Admin Portal (Restricted access)"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = [var.admin_allowed_cidr]
  }

  # Port 3001: Backend API direct access (for mobile app & testing)
  ingress {
    description = "Spring Boot Backend REST and WebSocket API"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: Full Internet access
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "servio-sg"
  }
}
