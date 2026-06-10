# Serverless Pastebin — Production-Grade AWS Infrastructure

![CI Status](https://img.shields.io/badge/CI-Passing-brightgreen)
![Terraform](https://img.shields.io/badge/Terraform-1.5+-blue)
![AWS](https://img.shields.io/badge/AWS-Serverless-orange)
![Python](https://img.shields.io/badge/Python-3.12-blue)

A production-grade Serverless Pastebin infrastructure deployed on AWS using Terraform.

## Architecture
*(Diagram placeholder)*

## Features
- **Infrastructure as Code (IaC):** Fully provisioned with Terraform.
- **Serverless Compute:** Python 3.12 AWS Lambda functions.
- **NoSQL Database:** DynamoDB with TTL for auto-expiring pastes.
- **Global CDN:** CloudFront serving static S3 frontend.
- **Observability:** CloudWatch Dashboards and Alarms configured.
- **Security:** OIDC for CI/CD, least-privilege IAM policies, AWS KMS.

## Prerequisites
- Terraform >= 1.5
- AWS CLI v2
- Python 3.12
- GitHub Account

## Quick Start
1. Clone the repository.
2. Configure AWS credentials locally (`aws configure`).
3. Navigate to `/terraform` and run `terraform init`.
4. Run `terraform apply -var="environment=dev"`.

## What I Learned
*(Placeholder for reflection on state management, DynamoDB access patterns, least-privilege IAM, etc.)*
