variable "project_name" { type = string }
variable "environment" { type = string }
variable "aws_region" { type = string }
variable "dynamodb_table_name" { type = string }
variable "alert_email" { 
  type = string
  default = ""
  description = "Email address to send CloudWatch alarms to"
}
