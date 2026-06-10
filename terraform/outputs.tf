output "dynamodb_table_name" {
  value = module.database.table_name
}

output "api_endpoint" {
  value = module.api.api_endpoint
}

output "cloudfront_domain_name" {
  value = module.cdn.cloudfront_domain_name
}

