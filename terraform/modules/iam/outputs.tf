output "creator_role_arn" {
  description = "ARN of the creator Lambda role"
  value       = aws_iam_role.creator_lambda.arn
}

output "retriever_role_arn" {
  description = "ARN of the retriever Lambda role"
  value       = aws_iam_role.retriever_lambda.arn
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions OIDC role"
  value       = aws_iam_role.github_actions.arn
}
