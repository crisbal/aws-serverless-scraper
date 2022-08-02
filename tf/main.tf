resource "aws_dynamodb_table" "listings" {
  name         = "Listings"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Id"

  attribute {
    name = "Id"
    type = "S"
  }
}

resource "aws_iam_role" "scrape_listing_role" {
  name = "scrape_listing_iam"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect = "Allow",
      }
    ]
  })
}

resource "aws_iam_role_policy" "scrape_listing_policy" {
  name = "scrape_listing_policy"
  role = aws_iam_role.scrape_listing_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action : [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
        Effect   = "Allow"
        Resource = aws_dynamodb_table.listings.arn
      }
    ]
  })
}

resource "aws_lambda_function" "scrape_listing_lambda" {
  function_name = "scrape_listing"
  handler       = "scrape_listing.handler"
  role          = aws_iam_role.scrape_listing_role.arn

  filename         = data.archive_file.lambda_code_scrape_listing_zip.output_path
  source_code_hash = data.archive_file.lambda_code_scrape_listing_zip.output_base64sha256

  runtime = "python3.9"

   environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.listings.name
    }
  }
}
