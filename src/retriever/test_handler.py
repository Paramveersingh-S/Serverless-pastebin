import os
import json
import time
import pytest
from unittest import mock

os.environ["TABLE_NAME"] = "test-table"

from .handler import lambda_handler

@mock.patch('src.retriever.handler.table')
def test_lambda_handler_missing_id(mock_table):
    event = {"pathParameters": {}}
    response = lambda_handler(event, None)
    assert response["statusCode"] == 400

@mock.patch('src.retriever.handler.table')
def test_lambda_handler_not_found(mock_table):
    mock_table.get_item.return_value = {}
    
    event = {"pathParameters": {"paste_id": "missing"}}
    response = lambda_handler(event, None)
    
    assert response["statusCode"] == 404

@mock.patch('src.retriever.handler.table')
def test_lambda_handler_success(mock_table):
    mock_table.get_item.return_value = {
        "Item": {
            "paste_id": "valid1",
            "content": "test",
            "created_at": "2024-01-01T00:00:00Z",
            "expires_at": int(time.time()) + 1000
        }
    }
    
    event = {"pathParameters": {"paste_id": "valid1"}}
    response = lambda_handler(event, None)
    
    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert body["content"] == "test"
