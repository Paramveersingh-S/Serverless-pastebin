# Scalability Analysis

This document outlines the scalability characteristics, limits, and scaling strategies for the Serverless Pastebin.

## 1. Current Architecture Limits

Our architecture uses purely serverless components which auto-scale by default, but have some soft and hard limits:

- **Lambda Concurrency**: Default 1,000 concurrent executions per region per account.
- **DynamoDB PAY_PER_REQUEST**: Automatically scales to accommodate unpredictable workloads without capacity planning. Limits are bounded by account-level settings (default 40K Read / 40K Write units per table).
- **API Gateway (HTTP API)**: 10,000 Requests Per Second (RPS) default soft limit per region.
- **CloudFront / S3**: Effectively unlimited for static asset delivery.

## 2. Bottleneck Analysis

| Component | Limit | How to Scale | Cost Implication |
|-----------|-------|--------------|------------------|
| **API Gateway** | 10k RPS | Request AWS support quota increase. | Linear (~$1.00 / million). |
| **Lambda** | 1k Concurrency | Request quota increase. Optimize code execution time. | Linear based on GB-seconds. |
| **DynamoDB** | 40k WCU/RCU | Partition key design prevents hot partitions. | PAY_PER_REQUEST scales linearly. |
| **CloudFront** | N/A | Scales automatically globally. | Bandwidth pricing (PriceClass_100). |

## 3. Scaling Trajectory

- **10x Traffic (100 RPS)**: Architecture handles this natively with zero configuration changes.
- **100x Traffic (1k RPS)**: Might experience DynamoDB throttling on extremely "hot" pastes (e.g. viral snippets). 
  - *Action*: Implement DynamoDB DAX (in-memory cache) or enable API Gateway response caching.
- **1,000x Traffic (10k RPS)**: Hitting account limits. 
  - *Action*: Implement Active-Active Multi-Region deployment using Route53 latency-based routing and DynamoDB Global Tables.

## 4. Cost Math (Estimation)

At 1 Million pastes created and 10 Million pastes read per month:
- **API Gateway**: 11M requests = ~$11.00
- **Lambda**: 11M invocations @ 128MB (avg 50ms) = ~$1.20
- **DynamoDB**: 10M reads, 1M writes = ~$3.75
- **CloudFront**: 100GB Data Transfer out = ~$8.50
- **Total Estimated Cost**: ~$24.45 / month (excluding Free Tier deductions).
