variable "project_name" { type = string }
variable "environment" { type = string }
variable "api_endpoint" { 
  type = string 
  description = "The API Gateway endpoint to route /api/* requests to"
}
