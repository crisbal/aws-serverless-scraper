terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.24"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.1.1"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "2.2.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.3.2"
    }
  }
}
