import os
import json
import uuid
import time
import logging
from datetime import datetime, timezone
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sqs_client = boto3.client("sqs")
QUEUE_URL = os.environ.get("ORDER_QUEUE_URL")

def lambda_handler(event, context):
    """
    HTTP API Gateway Proxy integration handler.
    Receives order payload, validates fields, and enqueues to SQS asynchronously.
    """
    logger.info("Received event: %s", json.dumps(event))

    try:
        # Handle API Gateway payload
        body = event.get("body")
        if isinstance(body, str):
            payload = json.loads(body)
        elif isinstance(body, dict):
            payload = body
        else:
            payload = event

        # Validation
        customer_id = payload.get("customer_id")
        amount = payload.get("amount")
        items = payload.get("items", [])

        if not customer_id or amount is None or float(amount) <= 0:
            return {
                "statusCode": 400,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": "Validation failed: 'customer_id' and positive 'amount' are required"}),
            }

        order_id = payload.get("order_id", f"ord-{uuid.uuid4().hex[:12]}")
        trace_id = os.environ.get("_X_AMZN_TRACE_ID", str(uuid.uuid4()))

        order_message = {
            "order_id": order_id,
            "customer_id": str(customer_id),
            "amount": float(amount),
            "currency": payload.get("currency", "USD"),
            "items_count": len(items) if items else int(payload.get("items_count", 1)),
            "created_at": datetime.now(timezone.utc).isoformat(),
            "trace_id": trace_id,
        }

        # Send to Amazon SQS
        if QUEUE_URL:
            sqs_client.send_message(
                QueueUrl=QUEUE_URL,
                MessageBody=json.dumps(order_message),
                MessageAttributes={
                    "EventType": {"DataType": "String", "StringValue": "OrderCreated"},
                    "TraceId": {"DataType": "String", "StringValue": trace_id},
                },
            )
            logger.info("Enqueued order %s to SQS queue %s", order_id, QUEUE_URL)

        return {
            "statusCode": 202,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "message": "Order accepted for asynchronous processing",
                "order_id": order_id,
                "status": "QUEUED",
                "timestamp": order_message["created_at"],
            }),
        }

    except Exception as e:
        logger.error("Error processing order request: %s", str(e), exc_info=True)
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "Internal server error processing order"}),
        }
