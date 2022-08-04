# A queue for listings that need to be scraped
resource "aws_sqs_queue" "listings_to_scrape" {
  name = "listings_to_scrape"
}

# A table to store the scraped listings
resource "aws_dynamodb_table" "listings" {
  name         = "Listings"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Id"

  attribute {
    name = "Id"
    type = "S"
  }
}

# A role for the lambda function to scrape listings
resource "aws_iam_role" "scrape_listing_role" {
  name = "scrape_listing_role"

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

# A policy for the previous role, which will allow writing to the DynamoDB table defined above, and getting data from the SQS queue
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

# This lambda function will scrape a listing pulled from the queue and add it to the DynamoDB table
resource "aws_lambda_function" "scrape_listing_lambda" {
  function_name = "scrape_listing"
  handler       = "scraper_lambdas.scrape_listing.handler"
  role          = aws_iam_role.scrape_listing_role.arn

  filename         = data.archive_file.lambda_code_scraper_lambdas_zip.output_path
  source_code_hash = data.archive_file.lambda_code_scraper_lambdas_zip.output_base64sha256

  runtime = "python3.9"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.listings.name
    }
  }
}

resource "aws_lambda_event_source_mapping" "run_scrape_listing_from_queue" {
  event_source_arn = aws_sqs_queue.listings_to_scrape.arn
  function_name    = aws_lambda_function.scrape_listing_lambda.arn
}

# A role for the lambda function to scrape listings
resource "aws_iam_role" "accept_scrape_role" {
  name = "accept_scrape_role"

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

# A policy for the previous role, which will allow writing to the DynamoDB table defined above, and getting data from the SQS queue
resource "aws_iam_role_policy" "accept_scrape_policy" {
  name = "accept_scrape_policy"
  role = aws_iam_role.accept_scrape_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action : [
          "sqs:GetQueueUrl",
          "sqs:SendMessage",
          "sqs:SetQueueAttributes",
        ],
        Effect   = "Allow"
        Resource = aws_sqs_queue.listings_to_scrape.arn
      }
    ]
  })
}

# This lambda function will add incoming requests to the SQS queue, after validation
resource "aws_lambda_function" "accept_scrape" {
  function_name = "accept_scrape"
  handler       = "scraper_lambdas.accept_scrape.handler"
  role          = aws_iam_role.accept_scrape_role.arn

  filename         = data.archive_file.lambda_code_scraper_lambdas_zip.output_path
  source_code_hash = data.archive_file.lambda_code_scraper_lambdas_zip.output_base64sha256

  runtime = "python3.9"

  environment {
    variables = {
      SQS_QUEUE_NAME = aws_sqs_queue.listings_to_scrape.name
    }
  }
}
