# AWS Serverless Deployment & Testing Guide

This guide explains how to deploy the serverless event-driven architecture using Terraform and test asynchronous message processing.

---

## 1. Prerequisites
- **AWS CLI v2** configured with valid credentials:
  ```bash
  aws sts get-caller-identity
  ```
- **Terraform CLI** installed (`>= 1.5.0`):
  ```bash
  terraform version
  ```

---

## 2. Deploying Infrastructure via Terraform

```bash
cd terraform

# 1. Initialize providers
terraform init

# 2. Review resources
terraform plan -out=tfplan

# 3. Apply infrastructure
terraform apply tfplan
```

### Outputs:
- `orders_post_url`: The API Gateway endpoint to submit orders.
- `sqs_queue_url`: The primary SQS queue URL.
- `dlq_url`: The Dead Letter Queue URL.
- `dynamodb_table_name`: The DynamoDB table name.

---

## 3. Submitting Test Orders

### A. Valid Order (202 Accepted)
```bash
curl -X POST https://<API_ENDPOINT>/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "cust_101",
    "amount": 250.00,
    "currency": "USD",
    "items": [{"sku": "PROD-A", "qty": 1}]
  }'
```

### B. Inspect Item in DynamoDB
```bash
aws dynamodb scan --table-name enterprise-order-event-platform-orders
```

### C. Testing Dead Letter Queue (DLQ)
Send a malformed payload directly to SQS to watch the consumer fail 3 times and route the message into the DLQ, triggering the CloudWatch alarm.

---

## 4. Teardown / Cleanup

```bash
cd terraform
terraform destroy -auto-approve
```
