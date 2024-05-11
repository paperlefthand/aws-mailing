resource "aws_iam_role" "bounce_receive_role" {
  name               = "bounce_receive_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "bounce_receive_role_basic_policy_attachment" {
  role       = aws_iam_role.bounce_receive_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "bounce_receive_sns_policy" {
  name = "bounce_receive_sns_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.lambda_bounce_receive.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Subscribe",
          "sns:Unsubscribe"
        ]
        Resource = aws_sns_topic.bounce-notification.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bounce_receive_sns_policy_attachment" {
  policy_arn = aws_iam_policy.bounce_receive_sns_policy.arn
  role       = aws_iam_role.bounce_receive_role.name
}

resource "aws_iam_role_policy_attachment" "bounce_receive_role_dynamodb_full_access" {
  role       = aws_iam_role.bounce_receive_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_lambda_permission" "sns_subscription_permission" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_bounce_receive.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_sns_topic.bounce-notification.arn
}

data "archive_file" "lambda_bounce_receive_package" {
  type        = "zip"
  source_dir  = "${path.root}/../functions/bounce_receive"
  output_path = "lambda_bounce_receive.zip"
}

resource "aws_lambda_function" "lambda_bounce_receive" {
  function_name    = "bounceReceive"
  filename         = "lambda_bounce_receive.zip"
  source_code_hash = filebase64sha256(data.archive_file.lambda_bounce_receive_package.output_path)
  role             = aws_iam_role.bounce_receive_role.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.12"
  timeout          = 3
  layers           = [var.powertools_layer_arn]
  environment {
    variables = {
      POWERTOOLS_LOG_LEVEL    = var.lambda_log_level,
      POWERTOOLS_SERVICE_NAME = "bounceReceive"
      TABLE_NAME              = aws_dynamodb_table.mailaddress.name,
    }
  }

}

