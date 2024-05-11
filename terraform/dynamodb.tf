resource "aws_dynamodb_table" "mailaddress" {
  name         = "mailaddress"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "email"
  attribute {
    name = "email"
    type = "S"
  }
  attribute {
    name = "haserror"
    type = "N"
  }
  global_secondary_index {
    name            = "haserror-index"
    hash_key        = "haserror"
    projection_type = "ALL"
  }

}


