resource "aws_iam_role" "send_mail_role" {
  name               = "send_mail_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "send_mail_role_basic_policy_attachment" {
  role       = aws_iam_role.send_mail_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "send_mail_role_sqs_full_access" {
  role       = aws_iam_role.send_mail_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "send_mail_role_ses_full_access" {
  role       = aws_iam_role.send_mail_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
}

resource "aws_iam_policy" "send_mail_s3_policy" {
  name        = "send_mail_s3_policy"
  description = "Policy for S3 access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.mailbody.arn}/*"
      }
    ]
  })
}

resource "aws_iam_policy" "send_mail_ses_policy" {
  name        = "send_mail_ses_policy"
  description = "Policy for SES access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ses:SendEmail"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "send_mail_role_s3_policy" {
  role       = aws_iam_role.send_mail_role.name
  policy_arn = aws_iam_policy.send_mail_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "send_mail_role_ses_policy" {
  role       = aws_iam_role.send_mail_role.name
  policy_arn = aws_iam_policy.send_mail_ses_policy.arn
}

# resource "aws_lambda_permission" "mailbody_permission" {
#   statement_id  = "AllowExecutionFromS3Bucket"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.lambda_send_mail.function_name
#   principal     = "s3.amazonaws.com"
#   source_arn    = aws_s3_bucket.mailbody.arn
# }

data "archive_file" "lambda_send_mail_package" {
  type        = "zip"
  source_dir  = "${path.root}/../functions/send_mail"
  output_path = "lambda_send_mail.zip"
}

resource "aws_lambda_function" "lambda_send_mail" {
  function_name    = "sendMail"
  filename         = "lambda_send_mail.zip"
  source_code_hash = filebase64sha256(data.archive_file.lambda_send_mail_package.output_path)
  role             = aws_iam_role.send_mail_role.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.11"
  timeout          = 3
  layers           = [var.powertools_layer_arn]
  environment {
    variables = {
      LOG_LEVEL               = "DEBUG",
      POWERTOOLS_SERVICE_NAME = "sendMail"
      # TABLE_NAME              = aws_dynamodb_table.mailaddress.name,
      # QUEUE_URL               = aws_sqs_queue.mailsendqueue.url,
      SENDER_MAIL_ADDRESS = aws_ssm_parameter.sender_mail_address.value
    }
  }
  tags = {
    Environment = "development"
  }
}
