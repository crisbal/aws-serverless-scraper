# A queue for the incoming URLS handled by this scraper
resource "aws_sqs_queue" "listings_to_scrape" {
  name = "${var.name}_listings_to_scrape"
}

# A role for the lambda function that will run the scraper
resource "aws_iam_role" "scraper_role" {
  name = "${var.name}_scraper_role"

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

# A policy for the role, which will allow writing to a DynamoDB table, and getting data from the SQS queue
resource "aws_iam_role_policy" "scraper_role_policy" {
  name = "${var.name}_scraper_role_policy"
  role = aws_iam_role.scraper_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action : [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
        Effect   = "Allow"
        Resource = var.dynamodb_table_arn
      },
      {
        Action : [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
        ],
        Effect   = "Allow"
        Resource = aws_sqs_queue.listings_to_scrape.arn
      }
    ]
  })
}

# This lambda function will scrape a listing URL pulled from the SQS queue and add it to the DynamoDB table
resource "aws_lambda_function" "scraper_lambda" {
  function_name = "${var.name}_scrape_listing"
  handler       = var.lambda_handler
  role          = aws_iam_role.scraper_role.arn

  filename         = data.archive_file.scraper_code_zip.output_path
  source_code_hash = data.archive_file.scraper_code_zip.output_base64sha256

  runtime = "python3.9"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
    }
  }
}

resource "aws_lambda_event_source_mapping" "run_scrape_listing_from_queue" {
  event_source_arn = aws_sqs_queue.listings_to_scrape.arn
  function_name    = aws_lambda_function.scraper_lambda.arn
}
