variable "aws_region" {
  type        = string
  description = "AWS deployment region"
  default     = "ap-south-1"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. production, staging, dev)"
  default     = "production"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance size (t3.micro for Free Tier, t4g.small for production)"
  default     = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "Name of the EC2 Key Pair already created in AWS Console"
  default     = "servio-key"
}

variable "ssh_allowed_cidr" {
  type        = string
  description = "CIDR block permitted to SSH into EC2 (e.g., your IP x.x.x.x/32)"
  default     = "0.0.0.0/0"
}

variable "admin_allowed_cidr" {
  type        = string
  description = "CIDR block permitted to access the Servio Admin Portal on port 8081"
  default     = "0.0.0.0/0"
}

variable "enable_s3_cloudfront" {
  type        = bool
  description = "Whether to provision S3 and CloudFront for Option B (Static Frontend CDN)"
  default     = true
}

variable "ses_sender_email" {
  type        = string
  description = "Sender email address to verify in Amazon SES for Supabase Auth transactional emails"
  default     = "noreply@servio.lk"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository owner and name (e.g. Servio-LK/Servio) for OIDC role trust"
  default     = "Servio-LK/Servio"
}
