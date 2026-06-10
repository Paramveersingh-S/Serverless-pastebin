variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table to grant access to"
  type        = string
}

variable "aws_region" {
  description = "AWS region for ARN construction"
  type        = string
  default     = "us-east-1"
}

variable "github_repo_owner" {
  description = "GitHub repository owner for OIDC trust policy"
  type        = string
  default     = "yourusername"
}

variable "github_repo_name" {
  description = "GitHub repository name for OIDC trust policy"
  type        = string
  default     = "serverless-pastebin"
}
