import os
import sys
import json
import pytest
from decimal import Decimal

# Set test AWS credentials before boto3 import
os.environ["AWS_DEFAULT_REGION"] = "us-east-1"
os.environ["AWS_ACCESS_KEY_ID"] = "testing"
os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
os.environ["ORDERS_TABLE_NAME"] = "test-orders-table"

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src")))

import producer
import consumer


def test_producer_validation_missing_customer():
    event = {"body": json.dumps({"amount": 50.0})}
    response = producer.lambda_handler(event, None)
    assert response["statusCode"] == 400
    data = json.loads(response["body"])
    assert "error" in data


def test_producer_validation_negative_amount():
    event = {"body": json.dumps({"customer_id": "cust_123", "amount": -10.0})}
    response = producer.lambda_handler(event, None)
    assert response["statusCode"] == 400


def test_producer_success_without_sqs():
    event = {
        "body": json.dumps({
            "customer_id": "cust_123",
            "amount": 100.0,
            "currency": "USD"
        })
    }
    response = producer.lambda_handler(event, None)
    assert response["statusCode"] == 202
    data = json.loads(response["body"])
    assert data["status"] == "QUEUED"
    assert data["order_id"].startswith("ord-")


def test_consumer_empty_batch():
    event = {"Records": []}
    result = consumer.lambda_handler(event, None)
    assert result == {"batchItemFailures": []}


def test_consumer_missing_order_id_reported_as_failure():
    event = {
        "Records": [
            {
                "messageId": "msg-999",
                "body": json.dumps({"customer_id": "cust_no_id"})
            }
        ]
    }
    result = consumer.lambda_handler(event, None)
    assert len(result["batchItemFailures"]) == 1
    assert result["batchItemFailures"][0]["itemIdentifier"] == "msg-999"
