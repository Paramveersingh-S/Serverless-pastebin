resource "aws_dynamodb_table" "pastes" {
  name         = "${var.project_name}-${var.environment}-pastes"
  
  # COST: PAY_PER_REQUEST stays in the free tier for low traffic (up to 25 WCU/RCU free if provisioned, but On-Demand is cheaper for spiky, low-volume workloads and often preferred for serverless).
  # Wait, Free Tier explicitly covers 25GB storage and 25 RCU/WCU for PROVISIONED. 
  # However, On-Demand (PAY_PER_REQUEST) is extremely cheap and requires zero capacity planning.
  billing_mode = "PAY_PER_REQUEST"
  
  hash_key     = "paste_id"

  attribute {
    name = "paste_id"
    type = "S"
  }

  attribute {
    name = "language"
    type = "S"
  }

  # Global Secondary Index to query pastes by language
  global_secondary_index {
    name               = "LanguageIndex"
    hash_key           = "language"
    projection_type    = "ALL"
  }

  # TTL to automatically expire old pastes and save storage cost
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  # Server-side encryption using AWS-owned keys is free
  server_side_encryption {
    enabled = true
  }

  # Point-in-time recovery is cost-prohibitive for dev, enable only in prod
  point_in_time_recovery {
    enabled = var.environment == "prod" ? true : false
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}
