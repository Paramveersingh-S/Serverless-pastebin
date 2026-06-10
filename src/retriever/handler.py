import os
import json
import time
import logging

import boto3
from botocore.exceptions import ClientError

# Configure structured logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

TABLE_NAME = os.environ.get("TABLE_NAME", "serverless-pastebin-dev-pastes")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    """
    Retrieves a paste by its short ID.
    Expected path parameter: /api/pastes/{paste_id}
    """
    start_time = time.time()
    
    # API Gateway HTTP API v2 payload format provides pathParameters
    path_parameters = event.get("pathParameters", {})
    paste_id = path_parameters.get("paste_id")
    
    if not paste_id:
        return {
            "statusCode": 400,
            "headers": {"Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"error": "Missing paste_id parameter."})
        }
        
    try:
        response = table.get_item(Key={"paste_id": paste_id})
        item = response.get("Item")
        
        # Check if item exists
        if not item:
            logger.info(json.dumps({
                "event": "paste_miss",
                "paste_id": paste_id,
                "latency_ms": round((time.time() - start_time) * 1000, 2)
            }))
            return {
                "statusCode": 404,
                "headers": {"Access-Control-Allow-Origin": "*"},
                "body": json.dumps({"error": "Paste not found."})
            }
            
        # Check if item is logically expired (DynamoDB TTL might take up to 48 hours to delete)
        current_time = int(time.time())
        if item.get("expires_at", 0) < current_time:
            logger.info(json.dumps({
                "event": "paste_expired",
                "paste_id": paste_id,
                "latency_ms": round((time.time() - start_time) * 1000, 2)
            }))
            return {
                "statusCode": 410,
                "headers": {"Access-Control-Allow-Origin": "*"},
                "body": json.dumps({"error": "Paste has expired and is no longer available."})
            }
            
        logger.info(json.dumps({
            "event": "paste_hit",
            "paste_id": paste_id,
            "language": item.get("language"),
            "latency_ms": round((time.time() - start_time) * 1000, 2)
        }))
        
        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "paste_id": item["paste_id"],
                "content": item["content"],
                "language": item.get("language", "plaintext"),
                "created_at": item["created_at"],
                "expires_at": int(item["expires_at"])
            })
        }
        
    except ClientError as e:
        logger.error(json.dumps({
            "event": "error",
            "message": str(e)
        }))
        return {
            "statusCode": 500,
            "headers": {"Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"error": "Internal server error."})
        }
