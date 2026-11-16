terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # Production remote state can be configured here:
  # backend "s3" {
  #   bucket         = "enterprise-serverless-tfstate"
  #   key            = "production/serverless/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "enterprise-serverless-tflocks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "AWS-Serverless-EventDriven-Architecture"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
