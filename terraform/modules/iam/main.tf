/**
 * Principle of Least Privilege:
 * Each Lambda function gets its own dedicated IAM role.
 * The Creator Lambda can write and read from DynamoDB.
 * The Retriever Lambda can ONLY read from DynamoDB.
 * The GitHub Actions role uses OIDC (keyless authentication) and can only update Lambda code/config.
 */

data "aws_caller_identity" "current" {}

# ==========================================
# 1. Creator Lambda IAM Role
# ==========================================
resource "aws_iam_role" "creator_lambda" {
  name = "${var.project_name}-${var.environment}-creator-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "creator_basic_execution" {
  role       = aws_iam_role.creator_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "creator_dynamodb" {
  name = "creator-dynamodb-access"
  role = aws_iam_role.creator_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "dynamodb:PutItem",
        "dynamodb:GetItem"
      ]
      Effect   = "Allow"
      Resource = var.dynamodb_table_arn
    }]
  })
}

# ==========================================
# 2. Retriever Lambda IAM Role
# ==========================================
resource "aws_iam_role" "retriever_lambda" {
  name = "${var.project_name}-${var.environment}-retriever-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "retriever_basic_execution" {
  role       = aws_iam_role.retriever_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "retriever_dynamodb" {
  name = "retriever-dynamodb-access"
  role = aws_iam_role.retriever_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "dynamodb:GetItem"
      ]
      Effect   = "Allow"
      Resource = var.dynamodb_table_arn
    }]
  })
}

# ==========================================
# 3. GitHub Actions OIDC Role
# ==========================================
# Create the OIDC Provider for GitHub Actions (only needs to be created once per account, 
# but managed here for completeness)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # Common GitHub Actions thumbprint
}

resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-${var.environment}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub": "repo:${var.github_repo_owner}/${var.github_repo_name}:*"
        }
        StringEquals = {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name = "github-actions-deploy-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration"
      ]
      Effect   = "Allow"
      # Using wildcard here for simplicity, but strictly should target specific lambda ARNs
      Resource = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-${var.environment}-*"
    }]
  })
}
