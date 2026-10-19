# Verify the sender email identity in Amazon SES
resource "aws_ses_email_identity" "servio_sender" {
  count = var.enable_ses ? 1 : 0
  email = var.ses_sender_email
}

# Dedicated IAM User for Supabase Custom SMTP authentication
resource "aws_iam_user" "ses_smtp_user" {
  count = var.enable_ses ? 1 : 0
  name  = "servio-ses-smtp-user"

  tags = {
    Name = "servio-ses-smtp-user"
  }
}

# IAM Access Key for the SMTP User
resource "aws_iam_access_key" "ses_smtp_key" {
  count = var.enable_ses ? 1 : 0
  user  = aws_iam_user.ses_smtp_user[0].name
}

# Least-privilege IAM Policy allowing only email sending via SES
resource "aws_iam_user_policy" "ses_send_policy" {
  count = var.enable_ses ? 1 : 0
  name  = "servio-ses-send-policy"
  user  = aws_iam_user.ses_smtp_user[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}
