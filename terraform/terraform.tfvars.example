# ==============================================================================
# Servio Infrastructure — Terraform Input Variables
# Copy this file to terraform.tfvars and customize the values for your AWS account.
# ==============================================================================

# AWS Deployment Region (Mumbai recommended for low latency in South Asia)
aws_region = "ap-south-1"

# Environment identifier
environment = "production"

# EC2 Instance Type
# - "t3.micro": 100% Free Tier eligible (1 vCPU, 1 GB RAM)
# - "t4g.small": Recommended production tier (2 vCPUs, 2 GB RAM Graviton ARM64)
instance_type = "t3.micro"

# The name of your existing EC2 Key Pair (created in AWS EC2 Console)
key_name = "servio-key"

# Security: Restrict SSH (port 22) to your specific public IP (e.g., "203.0.113.50/32")
ssh_allowed_cidr = "0.0.0.0/0"

# Security: Restrict the Admin Portal (port 8081) to your workshop office IP
admin_allowed_cidr = "0.0.0.0/0"

# Set to true if deploying frontend to S3 + CloudFront (Option B)
# Set to false if deploying full-stack Docker on EC2 (Option A)
enable_s3_cloudfront = true

# The sender email address to register with Amazon SES for Supabase Auth
ses_sender_email = "noreply@servio.lk"

# GitHub repository (Owner/Repo) for GitHub Actions OIDC deployment trust
github_repository = "Servio-LK/Servio"
