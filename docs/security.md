# Security Threat Model

## Asset Security

| Asset | Threat | Mitigation |
|-------|--------|------------|
| DynamoDB Data | Data exfiltration / Unauthorized access | Enforced strict Least-Privilege IAM roles for lambdas. DynamoDB is not publicly accessible. |
| DynamoDB Data | Data at rest exposure | Enabled AWS-managed Serverless-Side Encryption (SSE) for DynamoDB. |
| API Gateway | DDoS or volumetric attacks | HTTP APIs have default request throttling. CloudFront sits in front caching assets. |
| S3 Bucket (Frontend) | Accidental public bucket exposure | Enabled S3 Public Access Block at bucket level. Bucket policy only allows CloudFront OAC. |
| Lambda Source Code | Supply chain attacks | Bandit Python scanning and Checkov Terraform scanning in GitHub Actions CI. |

## Key Security Decisions
1. **OIDC for CI/CD**: Instead of creating IAM Users with long-lived access keys that could be leaked, we use GitHub Actions OIDC to assume an IAM role dynamically.
2. **CloudFront Origin Access Control (OAC)**: Modern replacement for OAI, ensuring S3 objects can strictly only be fetched via CloudFront, preventing direct S3 domain enumeration.
3. **CloudTrail Auditing**: All control-plane actions are logged to a dedicated S3 bucket to provide an audit trail for forensic analysis.
