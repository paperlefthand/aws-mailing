resource "aws_s3_bucket" "mailbody" {
  bucket = var.bucket_name
  # ファイルが残っていてもdestroyでバケットごと削除
  force_destroy = true
}

resource "aws_s3_bucket_notification" "mailbody_notification" {
  bucket = aws_s3_bucket.mailbody.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_send_queue.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = ""
    filter_suffix       = ".txt"
  }
}
