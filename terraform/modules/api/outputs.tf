output "api_endpoint" {
  description = "The default endpoint URL of the API Gateway"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}
