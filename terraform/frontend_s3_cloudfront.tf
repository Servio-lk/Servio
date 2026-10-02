# Look up current AWS Account ID for unique bucket naming
data "aws_caller_identity" "current" {}

# S3 Bucket for static React frontend hosting (Option B)
resource "aws_s3_bucket" "frontend" {
  count         = var.enable_s3_cloudfront ? 1 : 0
  bucket        = "servio-frontend-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name = "servio-frontend"
  }
}

# Block all public access (Best practice: access exclusively through CloudFront OAC)
resource "aws_s3_bucket_public_access_block" "frontend" {
  count                   = var.enable_s3_cloudfront ? 1 : 0
  bucket                  = aws_s3_bucket.frontend[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Origin Access Control (OAC)
resource "aws_cloudfront_origin_access_control" "frontend_oac" {
  count                             = var.enable_s3_cloudfront ? 1 : 0
  name                              = "servio-frontend-oac"
  description                       = "OAC for Servio Frontend S3 Bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Cache Policy (Managed - CachingOptimized)
data "aws_cloudfront_cache_policy" "caching_optimized" {
  count = var.enable_s3_cloudfront ? 1 : 0
  name  = "Managed-CachingOptimized"
}

# CloudFront Distribution for global CDN and automatic HTTPS
resource "aws_cloudfront_distribution" "frontend" {
  count               = var.enable_s3_cloudfront ? 1 : 0
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "Servio Frontend CDN"

  origin {
    domain_name              = aws_s3_bucket.frontend[0].bucket_regional_domain_name
    origin_id                = "servio-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend_oac[0].id
  }

  default_cache_behavior {
    target_origin_id       = "servio-s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized[0].id
    compress               = true
  }

  # SPA Routing: Redirect 403 & 404 errors to /index.html with HTTP 200
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "servio-frontend-distribution"
  }
}

# S3 Bucket Policy granting CloudFront OAC read permission
resource "aws_s3_bucket_policy" "frontend_oac_policy" {
  count  = var.enable_s3_cloudfront ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend[0].arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend[0].arn
          }
        }
      }
    ]
  })
}
