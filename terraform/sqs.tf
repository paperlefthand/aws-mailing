resource "aws_sqs_queue" "mailsendqueue" {
  name                        = "mailsendqueue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true    # MessageDeduplicationIdが不要
  deduplication_scope         = "queue" # キュー単位で重複排除
}

resource "aws_sqs_queue_policy" "mailsendqueue_policy" {
  queue_url = aws_sqs_queue.mailsendqueue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ]
        Resource = aws_sqs_queue.mailsendqueue.arn
      }
    ]
  })
}

resource "aws_lambda_event_source_mapping" "sqs_event_mapping" {
  event_source_arn = aws_sqs_queue.mailsendqueue.arn
  function_name    = aws_lambda_function.lambda_send_mail.function_name
  batch_size       = 10
}
