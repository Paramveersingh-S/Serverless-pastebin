terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # We are using local state for now until the AWS account is created.
  # Once ready, we will switch this to an S3 backend with DynamoDB locking.
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

module "database" {
  source = "./modules/database"
  project_name = var.project_name
  environment  = var.environment
}

module "iam" {
  source = "./modules/iam"
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  dynamodb_table_arn = module.database.table_arn
}

