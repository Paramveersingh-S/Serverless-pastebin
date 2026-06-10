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

module "api" {
  source = "./modules/api"
  project_name        = var.project_name
  environment         = var.environment
  dynamodb_table_name = module.database.table_name
  creator_role_arn    = module.iam.creator_role_arn
  retriever_role_arn  = module.iam.retriever_role_arn
}

module "cdn" {
  source = "./modules/cdn"
  project_name = var.project_name
  environment  = var.environment
  api_endpoint = module.api.api_endpoint
}


