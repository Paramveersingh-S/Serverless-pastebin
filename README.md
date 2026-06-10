# Serverless Pastebin — Production-Grade AWS Infrastructure

![CI Status](https://img.shields.io/badge/CI-Passing-brightgreen)
![Terraform](https://img.shields.io/badge/Terraform-1.5+-blue)
![AWS](https://img.shields.io/badge/AWS-Serverless-orange)
![Python](https://img.shields.io/badge/Python-3.12-blue)

A production-grade Serverless Pastebin infrastructure deployed on AWS using Terraform. Designed to be fully scalable, highly observable, and strictly secure while leveraging the AWS Free Tier.

## Architecture
See [Architecture Diagrams](docs/architecture.md) for full Mermaid sequence and component flows.

## Features
- **Infrastructure as Code (IaC):** 100% provisioned via modular Terraform.
- **Serverless Compute:** Python 3.12 AWS Lambda functions mapped via API Gateway HTTP APIs.
- **NoSQL Database:** DynamoDB with `PAY_PER_REQUEST` billing and native TTL for auto-expiring pastes.
- **Global CDN:** CloudFront edge delivery for a static HTML/JS frontend hosted securely in S3.
- **Observability:** Custom CloudWatch Dashboards tracking P95 latencies and error rates, with SNS Alarms.
- **Security:** OIDC for keyless CI/CD, least-privilege IAM policies, CloudTrail auditing, and S3 OAC.
- **Scalability Testing:** Included Locust load testing scripts.

## Tech Stack
| Layer | Technology | Why chosen |
|-------|------------|------------|
| **Compute** | AWS Lambda (Python 3.12) | Zero idle cost, scales instantly, no patching required. |
| **Database** | DynamoDB | Native TTL support, sub-10ms performance, cheap On-Demand mode. |
| **CDN & Storage** | CloudFront & S3 | Best-in-class static delivery. OAC ensures S3 is private. |
| **Routing** | API Gateway (HTTP APIs) | Cheaper and lower latency than REST APIs. Payload format 2.0. |
| **IaC** | Terraform | Industry standard, modular, multi-cloud capability. |
| **CI/CD** | GitHub Actions | Native OIDC support with AWS (no long-lived keys). |

## Quick Start
1. Clone the repository.
2. Navigate to `/terraform` and run `terraform init`.
3. Run `terraform apply -var="environment=dev"` to provision backend.
4. Run `cd ../scripts && ./upload_frontend.sh dev` to deploy UI.

## What I Learned
Through this project, I deepened my understanding of Day 2 operations. Configuring OIDC for GitHub Actions eliminated the anxiety of managing IAM Access Keys. Designing the IAM least-privilege policies forced me to map out exact DynamoDB API actions (`PutItem` vs `GetItem`) per Lambda, ensuring a compromised read-function couldn't write data. I also learned the nuances of CloudFront's modern Origin Access Control (OAC) vs the deprecated OAI.

## Documentation
- [Scalability Analysis](docs/scalability.md)
- [Security Threat Model](docs/security.md)
- [Architecture](docs/architecture.md)
