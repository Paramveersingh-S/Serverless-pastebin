import os
import json
import uuid
import time
import string
import random
import logging
from datetime import datetime

import boto3
from botocore.exceptions import ClientError

# Configure structured logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables
TABLE_NAME = os.environ.get("TABLE_NAME", "serverless-pastebin-dev-pastes")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "dev")

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)

def generate_short_code(length=6):
    """Generate a random base62 string."""
    characters = string.ascii_letters + string.digits
    return "".join(random.choice(characters) for _ in range(length))

def lambda_handler(event, context):
    """
    Creates a new paste.
    Expected body: {"content": "...", "language": "python", "ttl_days": 30}
    """
    try:
        body = json.loads(event.get("body", "{}"))
        content = body.get("content")
        language = body.get("language", "plaintext")
        ttl_days = int(body.get("ttl_days", 30))
        
        if not content:
            return {
                "statusCode": 400,
                "headers": {"Access-Control-Allow-Origin": "*"},
                "body": json.dumps({"error": "Missing 'content' in request body."})
            }

        # Max size check (e.g., 100KB)
        if len(content.encode('utf-8')) > 100 * 1024:
            return {
                "statusCode": 400,
                "headers": {"Access-Control-Allow-Origin": "*"},
                "body": json.dumps({"error": "Content exceeds 100KB limit."})
            }

        # Generate unique ID with collision retries
        max_retries = 3
        for attempt in range(max_retries):
            paste_id = generate_short_code()
            
            created_at = datetime.utcnow().isoformat() + "Z"
            expires_at = int(time.time()) + (ttl_days * 86400)

            item = {
                "paste_id": paste_id,
                "content": content,
                "language": language,
                "created_at": created_at,
                "expires_at": expires_at
            }

            try:
                # ConditionExpression ensures we don't overwrite an existing paste_id
                table.put_item(
                    Item=item,
                    ConditionExpression="attribute_not_exists(paste_id)"
                )
                
                logger.info(json.dumps({
                    "event": "paste_created",
                    "paste_id": paste_id,
                    "language": language,
                    "ttl_days": ttl_days
                }))
                
                return {
                    "statusCode": 201,
                    "headers": {
                        "Access-Control-Allow-Origin": "*",
                        "Content-Type": "application/json"
                    },
                    "body": json.dumps({
                        "paste_id": paste_id,
                        "language": language,
                        "expires_at": expires_at
                    })
                }
                
            except ClientError as e:
                if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
                    # Collision detected, try again
                    continue
                else:
                    raise e
                    
        # If we exhausted retries
        return {
            "statusCode": 409,
            "headers": {"Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"error": "Could not generate a unique ID. Please try again."})
        }
        
    except Exception as e:
        logger.error(json.dumps({
            "event": "error",
            "message": str(e)
        }))
        return {
            "statusCode": 500,
            "headers": {"Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"error": "Internal server error."})
        }
