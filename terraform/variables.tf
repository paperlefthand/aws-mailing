variable "aws_region" {
  description = "AWS region to deploy the infrastructure"
  default     = "ap-northeast-1"
}

variable "powertools_layer_arn" {
  description = "ARN of the Powertools layer"
  default     = "arn:aws:lambda:ap-northeast-1:017000801446:layer:AWSLambdaPowertoolsPythonV2:40"
}

variable "bucket_name" {
  description = "Name of the S3 bucket to store mail body"
  default     = "mailbody-asjdfajlsa"

}

variable "sender_mail_address" {
  description = "Mail address of the sender"
  type = string
}