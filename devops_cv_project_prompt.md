# 🚀 CV-WORTHY DEVOPS PROJECT — MASTER PROMPT FILE
### "Cloud-Native Scalable URL Shortener with Full Observability"
> A zero-cost, end-to-end Infrastructure-as-Code project using AWS Free Tier + Terraform
> Designed to impress interviewers at FAANG, startups, and cloud-native companies

---

## HOW TO USE THIS FILE

Paste each numbered section as a separate prompt to your AI model (Claude, GPT-4, etc.).
Work through them in order. Each section builds on the last.
Every section is self-contained — paste it, get output, save it, move on.

---

## PROJECT OVERVIEW (Read First)

**What you're building:** A production-grade URL Shortener service (like bit.ly) running on AWS.

**Why this project impresses employers:**
- It touches every layer of modern cloud engineering
- It uses real industry tools (Terraform, GitHub Actions, CloudWatch, DynamoDB)
- It's fully automated — no clicking in AWS console
- It demonstrates cost awareness (free tier discipline)
- It has observability, security, and CI/CD — the three things interviewers always ask about

**Architecture at a glance:**
```
User → CloudFront (CDN) → API Gateway → Lambda (Node.js/Python)
                                              ↓
                                         DynamoDB (URLs table)
                                              ↓
                              CloudWatch Logs + Alarms + Dashboard
```

**Free Tier coverage:**
- Lambda: 1M free requests/month
- DynamoDB: 25GB storage, 25 read/write units free forever
- API Gateway: 1M calls/month for 12 months
- CloudFront: 1TB transfer/month for 12 months
- S3: 5GB storage for 12 months
- CloudWatch: 10 custom metrics, 3 dashboards free

---

## SECTION 1 — PROJECT SCAFFOLDING & TERRAFORM SETUP

**Paste this prompt to your AI model:**

```
I am building a production-grade, CV-worthy DevOps project called "Serverless URL Shortener" on AWS using Terraform. Everything must stay within AWS Free Tier. Help me set up the project scaffold.

Generate the following:

1. A complete directory structure for the project. It should look like a real enterprise repo with these top-level folders:
   - /terraform          (all infrastructure code)
   - /src/shortener      (Lambda function source — use Python 3.12)
   - /src/redirector     (Lambda function source — use Python 3.12)
   - /.github/workflows  (CI/CD pipelines)
   - /docs               (architecture diagrams in Mermaid format)
   - /scripts            (helper bash scripts)

2. A root terraform/main.tf that:
   - Configures the AWS provider (us-east-1)
   - Sets up a remote backend using S3 + DynamoDB state locking
   - Defines local variables for project name, environment (dev/prod), and tags
   - Uses terraform workspaces to separate dev and prod

3. A terraform/variables.tf with:
   - project_name (default: "url-shortener")
   - environment (validation: must be dev or prod)
   - aws_region (default: us-east-1)
   - short_domain_prefix (the random prefix for short URLs)

4. A terraform/outputs.tf that exposes:
   - API Gateway invoke URL
   - CloudFront distribution domain
   - DynamoDB table name
   - Lambda function ARNs

5. A .gitignore appropriate for a Terraform + Python project

6. A README.md with:
   - Project title and architecture diagram placeholder
   - Prerequisites list (Terraform >= 1.5, AWS CLI v2, Python 3.12, GitHub account)
   - Step-by-step setup instructions from zero (including AWS account setup, IAM user creation with least-privilege policy)
   - How to deploy to dev and prod
   - How to run tests
   - A "What I learned" section placeholder

For each file, show the complete file content. Add inline comments explaining every non-obvious decision. Flag any line that relates to cost control with a comment: # COST: <reason>
```

---

## SECTION 2 — DYNAMODB + IAM WITH TERRAFORM

**Paste this prompt to your AI model:**

```
Continuing my "Serverless URL Shortener" Terraform project. Now build the DynamoDB table and IAM roles.

Create terraform/modules/database/main.tf for a DynamoDB module that:

1. Creates a DynamoDB table named "${var.project_name}-${var.environment}-urls" with:
   - Partition key: "short_code" (String)
   - Billing mode: PAY_PER_REQUEST  # COST: stays in free tier for low traffic
   - TTL attribute: "expires_at" so old short URLs auto-delete (saves storage)
   - Point-in-time recovery: enabled only for prod, disabled for dev (cost reason)
   - Server-side encryption using AWS-owned keys (free)
   - A Global Secondary Index on attribute "original_url" (String) for reverse lookups
   - Tags: Environment, Project, ManagedBy=Terraform

2. Create terraform/modules/iam/main.tf with:
   - An IAM role for the shortener Lambda with a trust policy for lambda.amazonaws.com
   - An IAM role for the redirector Lambda (separate role, least privilege)
   - A policy for shortener Lambda: dynamodb:PutItem, dynamodb:GetItem on the URLs table only
   - A policy for redirector Lambda: dynamodb:GetItem only on the URLs table
   - Both roles get AWSLambdaBasicExecutionRole attached (for CloudWatch Logs)
   - An IAM role for GitHub Actions OIDC (so CI/CD can deploy without storing AWS keys)
     - Trust policy: token.actions.githubusercontent.com
     - Permissions: lambda:UpdateFunctionCode, lambda:UpdateFunctionConfiguration only
     - This is the modern, secure, keyless CI/CD approach

3. For each module, also create:
   - variables.tf
   - outputs.tf

Show complete file contents with inline comments. Explain the principle of least privilege in a comment block at the top of the IAM module. Flag free-tier-relevant decisions with # COST comments.
```

---

## SECTION 3 — LAMBDA FUNCTIONS (APPLICATION CODE)

**Paste this prompt to your AI model:**

```
Continuing my Serverless URL Shortener. Now write the Lambda function application code in Python 3.12.

1. src/shortener/handler.py — The URL creation Lambda:
   - Accepts POST /shorten with JSON body: {"url": "https://...", "ttl_days": 30}
   - Validates the URL (must start with http:// or https://, max 2048 chars)
   - Generates a short code: 6-character base62 string (a-z, A-Z, 0-9)
   - Checks DynamoDB for collision, regenerates if collision found (max 3 retries)
   - Stores in DynamoDB: {short_code, original_url, created_at (ISO8601), expires_at (Unix timestamp), hit_count: 0}
   - Returns: {"short_url": "https://<DOMAIN>/<short_code>", "expires_at": "..."}
   - Returns proper HTTP status codes: 201 created, 400 bad input, 409 collision, 500 error
   - Adds CORS headers for browser clients
   - Uses structured logging (JSON format) for CloudWatch Insights queries

2. src/redirector/handler.py — The URL redirect Lambda:
   - Accepts GET /<short_code>
   - Looks up short_code in DynamoDB
   - If found and not expired: atomically increments hit_count using DynamoDB update expression, returns HTTP 301 redirect
   - If found but expired: returns 410 Gone with JSON error
   - If not found: returns 404 with JSON error
   - Structured JSON logging with: short_code, found (bool), latency_ms, request_id

3. src/shortener/requirements.txt and src/redirector/requirements.txt
   - boto3 is available in Lambda runtime (do NOT include it, it inflates package size)
   - Only include what's truly needed

4. src/shortener/test_handler.py — Unit tests using pytest + moto (mocks AWS):
   - Test valid URL shortening
   - Test invalid URL rejection
   - Test TTL calculation
   - Test collision handling
   - Test DynamoDB error handling

5. A Makefile at the project root with targets:
   - make test         — runs all pytest tests locally
   - make package      — zips Lambda functions for deployment
   - make deploy-dev   — terraform apply for dev workspace
   - make deploy-prod  — terraform apply for prod workspace (requires confirmation)
   - make destroy-dev  — destroys dev environment (safe teardown)

Show complete code. Add docstrings. Use type hints. Follow PEP8. The code should look like it was written by a senior engineer.
```

---

## SECTION 4 — API GATEWAY + LAMBDA TERRAFORM

**Paste this prompt to your AI model:**

```
Continuing the Serverless URL Shortener. Build the API Gateway v2 (HTTP API) and Lambda infrastructure in Terraform.

Create terraform/modules/api/main.tf that:

1. Creates an API Gateway v2 HTTP API named "${var.project_name}-${var.environment}":
   - CORS configuration: allow origins *, methods GET/POST/OPTIONS, headers Content-Type
   - Auto-deploy stage named $default
   # COST: HTTP API is cheaper than REST API — ~$1/million vs $3.50/million calls

2. Creates two Lambda functions from local zip archives:
   - shortener: runtime python3.12, handler handler.lambda_handler, memory 128MB (free tier max performance), timeout 10s
   - redirector: runtime python3.12, memory 128MB, timeout 5s
   - Both get environment variables: TABLE_NAME, DOMAIN, ENVIRONMENT
   - Both use the IAM roles from the IAM module

3. API routes:
   - POST /shorten → shortener Lambda (with Lambda integration, payload format 2.0)
   - GET /{short_code} → redirector Lambda

4. Lambda permissions allowing API Gateway to invoke each function

5. CloudWatch Log Groups for both Lambdas:
   - Retention: 7 days for dev, 30 days for prod
   # COST: shorter retention = less CloudWatch storage cost

6. A Lambda layer (optional, for dev) containing shared utility code

7. terraform/modules/api/variables.tf and outputs.tf

Also add to terraform/modules/api/main.tf:
- aws_lambda_function_event_invoke_config for both functions:
  - maximum_retry_attempts = 0 (important: prevent double-billing on errors)
  # COST: without this, Lambda retries failed invocations — you pay twice

Show complete Terraform HCL. Add a comment block explaining why HTTP API v2 was chosen over REST API. Explain payload format 2.0 vs 1.0.
```

---

## SECTION 5 — CLOUDFRONT CDN + S3 STATIC FRONTEND

**Paste this prompt to your AI model:**

```
Continuing the Serverless URL Shortener. Add a CloudFront distribution and a simple static frontend.

1. terraform/modules/cdn/main.tf:
   - S3 bucket for static website (the UI): 
     - Block all public access (serve only through CloudFront)
     - Versioning enabled
     - Name: "${var.project_name}-${var.environment}-frontend-${random_id}"
   - CloudFront Origin Access Control (OAC) — the modern replacement for OAI
   - CloudFront distribution with two origins:
     - Origin 1: S3 bucket (for static files, path: /*)
     - Origin 2: API Gateway (for API calls, path: /api/*)
   - Cache behaviors:
     - /api/* → API Gateway, cache disabled (TTL 0), all methods forwarded
     - /* → S3, cache enabled (default TTL 86400)
   - Price class: PriceClass_100 (US/EU only — cheapest)
   # COST: PriceClass_100 excludes expensive edge locations in Asia/South America
   - HTTPS only (redirect HTTP to HTTPS)
   - Custom error responses: 404 → /index.html (for SPA routing)

2. src/frontend/index.html — A clean, single-file frontend UI:
   - A text input for the long URL
   - A "Shorten" button
   - Displays the result short URL with a copy button
   - Shows an error message if the API returns an error
   - Plain HTML/CSS/JS, no frameworks, no build step needed
   - Fetches POST /api/shorten relative to the same CloudFront domain
   - Dark mode, clean design, professional look

3. scripts/upload_frontend.sh:
   - Syncs src/frontend/ to the S3 bucket
   - Invalidates CloudFront cache after upload: aws cloudfront create-invalidation
   - Takes ENVIRONMENT as argument

4. Update terraform/modules/cdn/outputs.tf to expose:
   - cloudfront_domain_name
   - s3_bucket_name
   - cloudfront_distribution_id

Show complete code. Explain why OAC is preferred over OAI in a comment block.
```

---

## SECTION 6 — OBSERVABILITY: CLOUDWATCH DASHBOARDS & ALARMS

**Paste this prompt to your AI model:**

```
Continuing the Serverless URL Shortener. Add full observability with CloudWatch.

Create terraform/modules/monitoring/main.tf:

1. CloudWatch Dashboard named "${var.project_name}-${var.environment}":
   A JSON dashboard with these widgets:
   - Lambda Invocations (both functions) — line graph, last 24h
   - Lambda Errors + Error Rate % — line graph
   - Lambda Duration P50/P95/P99 — line graph (this shows scalability awareness)
   - DynamoDB ConsumedReadCapacityUnits and ConsumedWriteCapacityUnits
   - DynamoDB SuccessfulRequestLatency
   - API Gateway 4xx and 5xx error counts
   - A text widget at the top with project name, environment, last deployed timestamp

2. CloudWatch Alarms (SNS → Email):
   - Lambda error rate > 5% over 5 minutes → ALARM
   - Lambda P95 duration > 3000ms → ALARM  
   - DynamoDB throttled requests > 0 → ALARM
   - All alarms go to an SNS topic: "${var.project_name}-${var.environment}-alerts"
   - SNS email subscription using var.alert_email (only create if alert_email is set)

3. CloudWatch Log Insights saved queries:
   - "Top 10 most visited short codes in last 24h"
     fields short_code, @timestamp | filter found = true | stats count() by short_code | sort count desc | limit 10
   - "Error analysis"
     fields @timestamp, @message | filter level = "ERROR" | sort @timestamp desc | limit 50

4. A Lambda function "url-analytics" (Python, 128MB, triggered every 5 min by EventBridge):
   - Queries DynamoDB Scan for total URL count and total hits
   - Pushes two custom CloudWatch metrics: TotalURLs and TotalHits (namespace: URLShortener)
   # COST: EventBridge rules are free up to 1M events/month; this uses ~8640/month

5. variables.tf with alert_email defaulting to "" and outputs.tf

Show complete Terraform HCL and Python code. Add a comment explaining why P95/P99 latency matters more than average for user experience. This section demonstrates to interviewers that you understand SRE principles.
```

---

## SECTION 7 — CI/CD WITH GITHUB ACTIONS

**Paste this prompt to your AI model:**

```
Continuing the Serverless URL Shortener. Build the complete CI/CD pipeline with GitHub Actions.

Create these GitHub Actions workflow files:

1. .github/workflows/ci.yml — Runs on every pull request:
   - Trigger: pull_request to main branch
   - Jobs:
     a. lint-and-test:
        - Python setup 3.12
        - pip install pytest moto boto3 flake8
        - flake8 src/ (linting)
        - pytest src/ --coverage (unit tests)
        - Upload coverage report as artifact
     b. terraform-validate:
        - Setup Terraform 1.5
        - terraform fmt -check (fails if formatting is wrong)
        - terraform init -backend=false
        - terraform validate
     c. security-scan:
        - Run checkov (Terraform security scanner) on terraform/
        - Run bandit (Python security scanner) on src/
        - This shows employers you understand DevSecOps

2. .github/workflows/deploy.yml — Runs on push to main:
   - Trigger: push to main branch
   - Uses OIDC to authenticate to AWS (no stored AWS keys — modern best practice)
     permissions: id-token: write, contents: read
     aws-actions/configure-aws-credentials with role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
   - Jobs (run in sequence with needs:):
     a. test — same as ci.yml lint-and-test
     b. build — zip both Lambda functions, upload to S3 artifacts bucket
     c. deploy-dev:
        - terraform workspace select dev
        - terraform apply -auto-approve
        - Run smoke test: curl the /health endpoint, assert 200
     d. integration-test:
        - POST to /api/shorten with a test URL
        - Assert 201 response and short_url in response
        - GET the short URL, assert 301 redirect
        - Fails fast if tests fail (prevents deploy to prod)
     e. deploy-prod:
        - Only runs if deploy-dev and integration-test pass
        - terraform workspace select prod
        - terraform apply -auto-approve
        - environment: production (adds GitHub environment protection rules)
        - Sends Slack notification on success/failure (optional, with webhook secret)

3. .github/workflows/destroy.yml — Manual teardown:
   - Trigger: workflow_dispatch (manual only, with environment input)
   - Runs terraform destroy for the selected environment
   - Requires typing "destroy" in a confirmation input
   - This prevents accidental destruction

4. A file docs/ci_cd_flow.md explaining:
   - Why OIDC is used instead of IAM access keys
   - The dev → integration test → prod promotion flow
   - How to add a new environment

Show complete YAML. Add comments on every non-obvious step. Make the pipeline look professional — proper job names, step names, and use of GitHub environments for prod protection.
```

---

## SECTION 8 — SECURITY HARDENING

**Paste this prompt to your AI model:**

```
Continuing the Serverless URL Shortener. Harden the security of the project. This section will make interviewers say "this person thinks about security."

Add the following to the Terraform codebase:

1. terraform/modules/security/main.tf:

   a. AWS WAF WebACL attached to CloudFront:
      - Rate limiting rule: max 100 requests per 5 minutes per IP → block
        # COST: WAF costs $5/month per WebACL — SKIP for free tier, but show the code commented out with explanation
      - Instead, use API Gateway usage plan with throttling:
        - Burst limit: 50, Rate limit: 10 req/sec
        - This is free and achieves similar protection
   
   b. S3 bucket policies:
      - Deny any s3:PutObject without server-side encryption
      - Deny access if not from CloudFront OAC
   
   c. Lambda environment variable encryption:
      - Use AWS KMS Customer Managed Key (CMK) for Lambda environment variable encryption
      - CMK costs $1/month — show with a variable use_kms_encryption (default false for dev, true for prod)

   d. CloudTrail (free tier: management events only):
      - Enable CloudTrail logging to S3 for all API calls
      - S3 bucket with lifecycle rule: delete logs after 90 days
      - This provides audit trail — important for compliance

2. A file docs/security.md with:
   - Threat model table: Asset | Threat | Mitigation (at least 8 rows covering: URL injection, DDoS, data exfiltration, privilege escalation, accidental exposure)
   - Security decisions log: every security choice made and why
   - What would be added with a budget: WAF, GuardDuty, Security Hub, Inspector

3. Add a .github/workflows/security.yml that runs weekly:
   - checkov on all Terraform
   - bandit on all Python
   - trivy on any Docker images (none yet, but show the pattern)
   - Posts results as a GitHub Security Advisory

Show complete code. The security.md file is particularly important — interviewers will ask "how would you secure this?" and you'll hand them this document.
```

---

## SECTION 9 — SCALABILITY & LOAD TESTING

**Paste this prompt to your AI model:**

```
Continuing the Serverless URL Shortener. Add scalability validation and load testing. This section shows employers you can prove your system works under load.

1. Create src/loadtest/locustfile.py using the Locust framework:
   - User behavior class "URLShortenerUser":
     - On start: pick a random real URL from a list of 100 URLs
     - Task 1 (weight 1): POST /api/shorten — shorten a random URL
     - Task 2 (weight 9): GET /<random short code from a shared pool> — redirect
     - Wait time: between 0.1 and 2 seconds (simulates real traffic)
   - A second class "HeavyWriteUser" for write-heavy load tests
   - Run configuration for 3 scenarios:
     a. Smoke test: 10 users, 1 min
     b. Load test: 100 users ramp over 2 min, hold 5 min
     c. Spike test: 0 → 500 users in 30 seconds

2. scripts/run_loadtest.sh:
   - Takes ENVIRONMENT and SCENARIO as arguments
   - Gets the CloudFront URL from Terraform output
   - Runs locust in headless mode
   - Saves HTML report to reports/loadtest-$(date).html
   - Prints pass/fail based on: error rate < 1%, P95 latency < 1000ms

3. docs/scalability.md — This is gold on a CV:
   
   Write a scalability analysis document covering:
   
   a. Current architecture limits:
      - Lambda concurrency: default 1000 concurrent executions per account
      - DynamoDB PAY_PER_REQUEST: auto-scales, no config needed
      - API Gateway: 10,000 RPS default (soft limit)
      - CloudFront: effectively unlimited
   
   b. Bottleneck analysis table:
      Component | Limit | How to scale | Cost implication
      (fill in for Lambda, DynamoDB, API GW, CloudFront, network)
   
   c. What would change at 10x, 100x, 1000x traffic:
      - 10x: Nothing changes, Lambda + DynamoDB scale automatically
      - 100x: Consider DynamoDB DAX caching for hot short codes (~$0.25/hr)
      - 1000x: Multi-region active-active with Route53 latency routing + DynamoDB Global Tables
   
   d. A Mermaid diagram showing the scaled-up architecture at 1000x
   
   e. Estimated AWS costs at each scale tier (show cost math)

4. Add a /health endpoint to the API:
   - GET /health → Lambda that checks DynamoDB connectivity
   - Returns: {"status": "ok", "dynamodb": "connected", "version": "1.0.0", "environment": "dev"}
   - Used by CI/CD smoke tests and CloudWatch Synthetics

Show complete code. The scalability.md is what separates senior candidates from junior ones.
```

---

## SECTION 10 — FINAL POLISH: README, ARCHITECTURE DIAGRAM & CV SUMMARY

**Paste this prompt to your AI model:**

```
I am finishing my "Serverless URL Shortener" DevOps project for my CV. Create the final documentation that makes this project stand out.

1. Complete README.md — replace the placeholder from Section 1:

   # Serverless URL Shortener — Production-Grade AWS Infrastructure

   Badges row: GitHub Actions CI badge | Terraform | AWS | Python | License MIT

   ## Architecture
   [Mermaid diagram showing full system]

   ## Features
   - Bullet list of every feature (IaC, CI/CD, observability, security, load tested)
   
   ## Tech Stack table:
   Layer | Technology | Why chosen
   (cover: compute, database, CDN, IaC, CI/CD, testing, monitoring, security)

   ## Quick Start (5 steps to deploy from zero)

   ## Project Structure (annotated tree)

   ## Infrastructure Details
   - DynamoDB schema and access patterns
   - Lambda cold start mitigation strategy
   - Cost breakdown table (estimated monthly for dev and prod)

   ## Observability
   - Dashboard screenshot placeholder
   - Available CloudWatch Insights queries

   ## Security
   - Link to docs/security.md
   - Key decisions summary

   ## Load Test Results
   - Table: Scenario | Users | RPS | P95 Latency | Error Rate
   - Interpretation paragraph

   ## What I Learned
   [Write a genuine 400-word reflection covering: Terraform state management challenges,
    DynamoDB access pattern design, least-privilege IAM, OIDC vs access keys,
    the value of structured logging, what I'd do differently]

   ## Future Improvements
   - Multi-region deployment with Route53 failover
   - Custom domain with ACM certificate
   - DynamoDB DAX for hot key caching
   - URL analytics dashboard with QuickSight
   - Blue/green Lambda deployments using aliases and weighted routing

2. docs/architecture.md:
   - Three Mermaid diagrams:
     a. Component diagram (what connects to what)
     b. Sequence diagram (POST /shorten end-to-end request flow)
     c. Deployment diagram (GitHub Actions → AWS)

3. A 200-word CV bullet point summary for the candidate to paste into their resume:
   - Written in strong action-verb CV language
   - Quantify everything (e.g. "handles 10,000 RPS", "< $0 cost on free tier", "sub-100ms P95 latency")
   - Mention specific technologies by name
   - Mention the challenges solved

4. A list of 15 interview questions this project prepares you to answer confidently, with 2-sentence answer starters for each.

Show complete markdown. The README is the project's face — make it look like a staff engineer wrote it.
```

---

## BONUS SECTION — EXTEND FOR MAXIMUM IMPACT

Once the core project is done, use these prompts to add more depth:

### Bonus A — Multi-Environment with Terraform Workspaces
```
Show me how to extend this project to support a staging environment between dev and prod, 
using Terraform workspaces and a separate tfvars file per environment. 
Include environment-specific CloudWatch alarm thresholds.
```

### Bonus B — Cost Optimization Report
```
Generate a real AWS Cost Explorer analysis for this project. 
Show exact free tier usage percentages for Lambda, DynamoDB, API Gateway, 
CloudFront, and S3. Show what happens to cost if traffic grows to 1M requests/day 
and how Reserved Capacity or Savings Plans would reduce that cost.
```

### Bonus C — Disaster Recovery Runbook
```
Write a disaster recovery runbook for the URL Shortener. Cover: 
Lambda failure, DynamoDB table deletion, S3 bucket corruption, CloudFront origin failure. 
For each: detection method, recovery steps, estimated RTO and RPO. 
This shows SRE maturity.
```

### Bonus D — Migrate to Containers (if interviewing at a Kubernetes shop)
```
Show how to migrate the Lambda functions to Docker containers running on ECS Fargate.
Keep the same API Gateway front-end. Compare cost, cold start, and operational complexity
vs the Lambda version. Use Terraform for all ECS/Fargate resources.
```

---

## TIPS FOR USING THIS ON YOUR CV

1. **Host the code on GitHub** — make it public, pin it to your profile
2. **Deploy it for real** — have a live demo URL ready (it costs $0 on free tier)
3. **Record a 3-minute demo video** — screen record showing the UI, the CloudWatch dashboard, and the CI/CD pipeline running. Host on YouTube (unlisted is fine). Add the link to the README.
4. **Write a blog post** — dev.to or Medium, "How I built a production-grade URL shortener for $0". This multiplies the signal.
5. **Get the GitHub Actions badge green** — recruiters look at that badge. Green = professional.

---

## SKILLS THIS PROJECT DEMONSTRATES

| Skill | Evidence |
|-------|----------|
| Infrastructure as Code | Entire project in Terraform, modular structure |
| AWS Services | Lambda, DynamoDB, API GW, CloudFront, S3, CloudWatch, IAM, WAF |
| CI/CD | GitHub Actions with OIDC, multi-stage, smoke tests |
| Python | Production-quality Lambda code with tests |
| Observability | CloudWatch dashboards, alarms, structured logging, Insights queries |
| Security | Least-privilege IAM, OIDC, CloudTrail, S3 policies, threat model |
| Cost Engineering | Free tier discipline, per-resource cost annotations |
| Scalability | Load testing, bottleneck analysis, scaling strategy doc |
| Documentation | Architecture diagrams, runbooks, decision logs |

---

*Generated for a zero-cost, CV-worthy DevOps portfolio project.*
*Estimated time to complete all 10 sections: 15–25 hours of focused work.*
*Estimated AWS cost: $0 (AWS Free Tier for 12 months)*
