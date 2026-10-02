# Look up the latest Ubuntu 22.04 LTS AMI for x86_64 or ARM64 depending on instance type
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = [startswith(var.instance_type, "t4g") ? "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*" : "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance for Servio Backend / All-in-One Host
resource "aws_instance" "servio_backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.servio_sg.id]

  # 20 GB gp3 encrypted root disk (fits within AWS 30 GB Free Tier EBS limit)
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    delete_on_termination = true
    tags = {
      Name = "servio-backend-root"
    }
  }

  # Cloud-init User Data script
  user_data = <<-EOF
              #!/bin/bash
              set -ex

              # 1. Enable 1 GB Swap Memory (Critical for t3.micro stability)
              if [ ! -f /swapfile ]; then
                dd if=/dev/zero of=/swapfile bs=1M count=1024
                chmod 600 /swapfile
                mkswap /swapfile
                swapon /swapfile
                echo '/swapfile swap swap defaults 0 0' >> /etc/fstab
              fi

              # 2. System updates and base tools
              apt-get update -y
              apt-get install -y ca-certificates curl gnupg lsb-release git unzip jq

              # 3. Install Official Docker Engine & Compose Plugin
              install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              chmod a+r /etc/apt/keyrings/docker.gpg

              echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu

              # 4. Configure Docker daemon log rotation to prevent disk exhaustion
              cat > /etc/docker/daemon.json << 'DOCKER_EOF'
              {
                "log-driver": "json-file",
                "log-opts": {
                  "max-size": "10m",
                  "max-file": "3"
                }
              }
              DOCKER_EOF
              systemctl restart docker

              # 5. Prepare application deployment directory
              mkdir -p /home/ubuntu/servio
              chown -R ubuntu:ubuntu /home/ubuntu/servio

              echo "Servio EC2 Host Provisioning Completed Successfully!" > /var/log/servio-init.log
              EOF

  tags = {
    Name = "servio-backend"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# Elastic IP allocation and association
resource "aws_eip" "servio_eip" {
  instance = aws_instance.servio_backend.id
  domain   = "vpc"

  tags = {
    Name = "servio-eip"
  }

  depends_on = [aws_instance.servio_backend]
}
