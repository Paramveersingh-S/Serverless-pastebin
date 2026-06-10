import os
import json
import pytest
from unittest import mock

# Mock environment variables before importing handler
os.environ["TABLE_NAME"] = "test-table"

from .handler import lambda_handler

@mock.patch('src.creator.handler.table')
def test_lambda_handler_missing_content(mock_table):
    event = {
        "body": json.dumps({"language": "python"})
    }
    response = lambda_handler(event, None)
    
    assert response["statusCode"] == 400
    body = json.loads(response["body"])
    assert "Missing 'content'" in body["error"]

@mock.patch('src.creator.handler.table')
def test_lambda_handler_success(mock_table):
    mock_table.put_item.return_value = {}
    
    event = {
        "body": json.dumps({"content": "print('hello')", "language": "python"})
    }
    response = lambda_handler(event, None)
    
    assert response["statusCode"] == 201
    body = json.loads(response["body"])
    assert "paste_id" in body
    assert body["language"] == "python"
