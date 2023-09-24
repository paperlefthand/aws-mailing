resource "aws_iam_role" "send_queue_role" {
  name               = "send_queue_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "send_queue_role_basic_policy_attachment" {
  role       = aws_iam_role.send_queue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "send_queue_role_sqs_full_access" {
  role       = aws_iam_role.send_queue_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "send_queue_role_dynamodb_read_access" {
  role       = aws_iam_role.send_queue_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
}

resource "aws_lambda_permission" "mailbody_bucket_permission" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_send_queue.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.mailbody.arn
}

data "archive_file" "lambda_send_queue_package" {
  type        = "zip"
  source_dir  = "${path.root}/../functions/send_queue"
  output_path = "lambda_send_queue.zip"
}

resource "aws_lambda_function" "lambda_send_queue" {
  function_name    = "sendQueue"
  filename         = "lambda_send_queue.zip"
  source_code_hash = filebase64sha256(data.archive_file.lambda_send_queue_package.output_path)
  role             = aws_iam_role.send_queue_role.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.11"
  timeout          = 3
  layers           = [var.powertools_layer_arn]
  environment {
    variables = {
      LOG_LEVEL               = "DEBUG",
      POWERTOOLS_SERVICE_NAME = "sendQueue"
      TABLE_NAME              = aws_dynamodb_table.mailaddress.name,
      QUEUE_URL               = aws_sqs_queue.mailsendqueue.url,
    }
  }
  tags = {
    Environment = "development"
  }
}
