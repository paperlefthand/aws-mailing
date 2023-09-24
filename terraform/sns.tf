resource "aws_sns_topic" "bounce-notification" {
  name = "bounce-notification"
}

resource "aws_sns_topic_subscription" "bounce-notification" {
  topic_arn = aws_sns_topic.bounce-notification.arn
  protocol = "lambda"
  endpoint = aws_lambda_function.lambda_bounce_receive.arn
}
