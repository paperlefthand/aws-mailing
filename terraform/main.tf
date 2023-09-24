resource "aws_ssm_parameter" "sender_mail_address" {
  name  = "/development/sender_mail_address"
  type  = "String"
  value = var.sender_mail_address

  tags = {
    environment = "development"
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}