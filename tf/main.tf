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

module "scraper_one" {
  name   = "scraper_one"
  source = "./modules/scraper"

  python_package_path = "${path.root}/../src/scraper-lambdas"
  package_name        = "scraper_lambdas"
  lambda_handler      = "scraper_lambdas.scraper_one.handler"
  dynamodb_table_arn  = aws_dynamodb_table.listings.arn
  dynamodb_table_name = aws_dynamodb_table.listings.name
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
        Resource = module.scraper_one.sqs_queue.arn
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
      SQS_QUEUE_NAME = module.scraper_one.sqs_queue.name
    }
  }
}
