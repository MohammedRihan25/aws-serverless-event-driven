import os
import json
import logging
from decimal import Decimal
from datetime import datetime, timezone
import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
TABLE_NAME = os.environ.get("ORDERS_TABLE_NAME", "enterprise-orders")
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    """
    SQS Event Source Mapping Consumer.
    Processes batches of order messages and persists them idempotently into DynamoDB.
    Returns batchItemFailures for partial batch failure handling in SQS.
    """
    batch_item_failures = []
    records = event.get("Records", [])
    logger.info("Processing %d records from SQS", len(records))

    for record in records:
        message_id = record.get("messageId")
        try:
            body_str = record.get("body", "{}")
            order = json.loads(body_str)

            order_id = order.get("order_id")
            if not order_id:
                raise ValueError("Missing 'order_id' in SQS payload")

            # Parse amount as Decimal for DynamoDB precision
            amount_decimal = Decimal(str(order.get("amount", 0.0)))

            item = {
                "order_id": order_id,
                "created_at": order.get("created_at", datetime.now(timezone.utc).isoformat()),
                "customer_id": order.get("customer_id", "anonymous"),
                "amount": amount_decimal,
                "currency": order.get("currency", "USD"),
                "status": "COMPLETED",
                "processed_at": datetime.now(timezone.utc).isoformat(),
                "trace_id": order.get("trace_id", "unknown"),
            }

            # Idempotent write using conditional expression (write if order doesn't exist)
            table.put_item(
                Item=item,
                ConditionExpression="attribute_not_exists(order_id)",
            )
            logger.info("Successfully persisted order %s to DynamoDB table %s", order_id, TABLE_NAME)

        except ClientError as e:
            if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
                # Duplicate event already processed (idempotent success)
                logger.warning("Order %s already processed. Skipping duplicate.", order.get("order_id"))
            else:
                logger.error("DynamoDB client error for record %s: %s", message_id, str(e), exc_info=True)
                batch_item_failures.append({"itemIdentifier": message_id})
        except Exception as err:
            logger.error("Unhandled error processing message %s: %s", message_id, str(err), exc_info=True)
            batch_item_failures.append({"itemIdentifier": message_id})

    logger.info("Batch finished: %d failed of %d records", len(batch_item_failures), len(records))
    return {"batchItemFailures": batch_item_failures}
