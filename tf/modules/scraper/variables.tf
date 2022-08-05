variable "name" {
  type        = string
  description = "Name of this scraper"
}

variable "python_package_path" {
  type        = string
  description = "Path to source code of the Python package for this scraper"
}

variable "package_name" {
  type        = string
  description = "Name of the package"
}

variable "lambda_handler" {
  type        = string
  description = "Specification for the lambda handler"
}

variable "dynamodb_table_arn" {
  type = string
}

variable "dynamodb_table_name" {
  type = string
}
