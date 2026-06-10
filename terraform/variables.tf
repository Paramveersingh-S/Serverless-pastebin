variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "serverless-pastebin"
}

variable "environment" {
  description = "The deployment environment (dev or prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

variable "aws_region" {
  description = "The AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}
