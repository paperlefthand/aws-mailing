resource "aws_ses_email_identity" "email" {
  email = var.sender_mail_address
}

resource "aws_ses_identity_notification_topic" "bounce-notification" {
  topic_arn                = aws_sns_topic.bounce-notification.arn
  notification_type        = "Bounce"
  identity                 = aws_ses_email_identity.email.email
  include_original_headers = true
}
