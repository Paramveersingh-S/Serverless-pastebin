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
  region                      = var.aws_region
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    apigatewayv2 = "http://localhost:4566"
    cloudfront   = "http://localhost:4566"
    cloudtrail   = "http://localhost:4566"
    cloudwatch   = "http://localhost:4566"
    dynamodb     = "http://localhost:4566"
    iam          = "http://localhost:4566"
    lambda       = "http://localhost:4566"
    s3           = "http://localhost:4566"
    sns          = "http://localhost:4566"
    sts          = "http://localhost:4566"
  }

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

module "monitoring" {
  source = "./modules/monitoring"
  project_name        = var.project_name
  environment         = var.environment
  aws_region          = var.aws_region
  dynamodb_table_name = module.database.table_name
  alert_email         = "" # Update with real email in tfvars
}

module "security" {
  source = "./modules/security"
  project_name = var.project_name
  environment  = var.environment
}


