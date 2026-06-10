data "archive_file" "creator_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../src/creator"
  output_path = "${path.root}/../src/creator.zip"
}

data "archive_file" "retriever_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../src/retriever"
  output_path = "${path.root}/../src/retriever.zip"
}

# ==========================================
# 1. API Gateway v2 (HTTP API)
# COST: HTTP API is significantly cheaper than REST API (~$1/million vs $3.50/million)
# and provides lower latency.
# ==========================================
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-${var.environment}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Content-Type"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/api_gw/${aws_apigatewayv2_api.http_api.name}"
  retention_in_days = var.environment == "prod" ? 30 : 7
}

# ==========================================
# 2. Lambdas
# ==========================================
resource "aws_lambda_function" "creator" {
  filename         = data.archive_file.creator_zip.output_path
  source_code_hash = data.archive_file.creator_zip.output_base64sha256
  function_name    = "${var.project_name}-${var.environment}-creator"
  role             = var.creator_role_arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  memory_size      = 128
  timeout          = 10

  environment {
    variables = {
      TABLE_NAME  = var.dynamodb_table_name
      ENVIRONMENT = var.environment
    }
  }
}

resource "aws_lambda_function" "retriever" {
  filename         = data.archive_file.retriever_zip.output_path
  source_code_hash = data.archive_file.retriever_zip.output_base64sha256
  function_name    = "${var.project_name}-${var.environment}-retriever"
  role             = var.retriever_role_arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  memory_size      = 128
  timeout          = 5

  environment {
    variables = {
      TABLE_NAME  = var.dynamodb_table_name
      ENVIRONMENT = var.environment
    }
  }
}

# CloudWatch Log Groups for Lambdas
resource "aws_cloudwatch_log_group" "creator_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.creator.function_name}"
  retention_in_days = var.environment == "prod" ? 30 : 7
}

resource "aws_cloudwatch_log_group" "retriever_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.retriever.function_name}"
  retention_in_days = var.environment == "prod" ? 30 : 7
}

# Prevent double-billing on async retries
resource "aws_lambda_function_event_invoke_config" "creator_config" {
  function_name                = aws_lambda_function.creator.function_name
  maximum_retry_attempts       = 0
}

resource "aws_lambda_function_event_invoke_config" "retriever_config" {
  function_name                = aws_lambda_function.retriever.function_name
  maximum_retry_attempts       = 0
}

# ==========================================
# 3. API Gateway Routes & Integrations
# ==========================================
resource "aws_apigatewayv2_integration" "creator_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.creator.invoke_arn
  payload_format_version = "2.0" # Payload format 2.0 simplifies the request/response structures
}

resource "aws_apigatewayv2_route" "creator_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /api/pastes"
  target    = "integrations/${aws_apigatewayv2_integration.creator_integration.id}"
}

resource "aws_apigatewayv2_integration" "retriever_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.retriever.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "retriever_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /api/pastes/{paste_id}"
  target    = "integrations/${aws_apigatewayv2_integration.retriever_integration.id}"
}

# Allow API Gateway to invoke the Lambdas
resource "aws_lambda_permission" "creator_api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.creator.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "retriever_api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.retriever.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
