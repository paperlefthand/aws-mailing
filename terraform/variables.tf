# 実行環境によって変更したいパラメータはここに集約
# 秘匿したいものはterraform.tfvarsで管理

variable "aws_region" {
  description = "AWS region to deploy the infrastructure"
  default     = "ap-northeast-1"
  type        = string
}

variable "powertools_layer_arn" {
  description = "ARN of the Powertools layer"
  default     = "arn:aws:lambda:ap-northeast-1:017000801446:layer:AWSLambdaPowertoolsPythonV2:69"
  type        = string
}

variable "bucket_name" {
  description = "テキストファイルをuplaodするS3バケット"
  type        = string
}

variable "sender_mail_address" {
  description = "メール配信元のアドレス"
  type        = string
}

variable "aws_profile" {
  type = string
}

variable "environment" {
  default = "development"
  type    = string
}

variable "lambda_log_level" {
  default = "DEBUG"
  type    = string
}

