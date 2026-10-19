output "elastic_ip" {
  description = "Public Elastic IP assigned to the Servio EC2 instance"
  value       = aws_eip.servio_eip.public_ip
}

output "ssh_command" {
  description = "SSH connection string to connect to the EC2 instance"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_eip.servio_eip.public_ip}"
}

output "customer_portal_url" {
  description = "Customer Web Portal URL (Option A - Port 80)"
  value       = "http://${aws_eip.servio_eip.public_ip}"
}

output "admin_portal_url" {
  description = "Admin Portal URL (Option A - Port 8081)"
  value       = "http://${aws_eip.servio_eip.public_ip}:8081"
}

output "backend_api_url" {
  description = "Spring Boot REST and WebSocket API URL"
  value       = "http://${aws_eip.servio_eip.public_ip}:3001"
}

output "cloudfront_domain_name" {
  description = "CloudFront HTTPS Distribution URL (Option B)"
  value       = var.enable_s3_cloudfront ? "https://${aws_cloudfront_distribution.frontend[0].domain_name}" : "Disabled"
}

output "s3_frontend_bucket" {
  description = "S3 Bucket Name for Frontend deployment (Option B)"
  value       = var.enable_s3_cloudfront ? aws_s3_bucket.frontend[0].id : "Disabled"
}

output "ses_smtp_host" {
  description = "Amazon SES SMTP Endpoint for Supabase Auth Settings"
  value       = var.enable_ses ? "email-smtp.${var.aws_region}.amazonaws.com" : "Disabled"
}

output "ses_smtp_username" {
  description = "Amazon SES SMTP Username (IAM Access Key ID)"
  value       = var.enable_ses ? aws_iam_access_key.ses_smtp_key[0].id : "Disabled"
}

output "ses_smtp_password" {
  description = "Amazon SES SMTP Derived Password for Supabase Custom SMTP"
  value       = var.enable_ses ? aws_iam_access_key.ses_smtp_key[0].ses_smtp_password_v4 : "Disabled"
  sensitive   = true
}

output "github_actions_role_arn" {
  description = "IAM Role ARN to configure in GitHub Secrets (AWS_ROLE_ARN)"
  value       = var.enable_github_oidc ? aws_iam_role.github_actions[0].arn : "Disabled"
}
