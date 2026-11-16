# Enterprise AWS Serverless Event-Driven Architecture with Terraform & Distributed Tracing

[![Serverless CI](https://img.shields.io/badge/CI%2FCD-Serverless_CI-blue?logo=githubactions&logoColor=white)](#-event-driven-architecture)
[![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS Lambda](https://img.shields.io/badge/AWS-Lambda_Python_3.12-FF9900?logo=awslambda&logoColor=white)](https://aws.amazon.com/lambda/)
[![Amazon SQS](https://img.shields.io/badge/AWS-SQS_with_DLQ-FF4F8B?logo=amazonsqs&logoColor=white)](https://aws.amazon.com/sqs/)
[![Amazon DynamoDB](https://img.shields.io/badge/AWS-DynamoDB_On--Demand-4053D6?logo=amazondynamodb&logoColor=white)](https://aws.amazon.com/dynamodb/)
[![AWS X-Ray](https://img.shields.io/badge/Observability-AWS_X--Ray_Tracing-1D8102?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/xray/)

A high-performance, asynchronous, serverless transaction processing platform built on **AWS Lambda (Python 3.12)**, **Amazon API Gateway v2**, **Amazon SQS** with automated **Dead Letter Queue (DLQ)** retry handling, and **Amazon DynamoDB**, fully provisioned with **Terraform** and instrumented with **AWS X-Ray** distributed tracing.

---

## 🏛️ Event-Driven Architecture

```mermaid
flowchart TD
    Client["Client / Webhook"] -->|POST /orders| APIGW["Amazon API Gateway (HTTP v2)"]
    APIGW -->|Proxy Integration| Producer["Producer Lambda (Python 3.12)"]

    Producer -->|Inject Trace ID + Enqueue| SQS["Amazon SQS Orders Queue"]
    Producer -->|202 Accepted Response| Client

    SQS -->|Batch Size: 10| Consumer["Consumer Lambda (Python 3.12)"]
    Consumer -->|Idempotent PutItem| DDB[("Amazon DynamoDB Orders Table")]

    subgraph ErrorHandling ["Dead Letter Queue (DLQ) & Alarms"]
        SQS -.->|Failures > 3 Retries| DLQ["SQS Dead Letter Queue (DLQ)"]
        DLQ -->|Messages >= 1| Alarm["CloudWatch Critical DLQ Alarm"]
    end

    subgraph Observability ["Distributed Tracing"]
        XRay["AWS X-Ray Trace Engine"]
        Producer -.->|Trace Segments| XRay
        Consumer -.->|Trace Segments| XRay
    end
```

---

## 🚀 Key Architectural Highlights

1. **Non-Blocking Ingestion:** Clients receive immediate `202 Accepted` confirmation (< 30ms latency) while heavy processing occurs asynchronously.
2. **Resilient Failure Isolation (DLQ):** Messages that fail 3 consecutive attempts are quarantined in an SQS Dead Letter Queue with a 14-day retention window for offline inspection, triggering an automated CloudWatch alarm.
3. **Partial Batch Failure Handling (`ReportBatchItemFailures`):** Employs SQS partial batch responses so only genuinely failed records are retried, preventing unnecessary re-processing of successful records.
4. **Idempotent Storage:** Uses DynamoDB conditional writes (`attribute_not_exists(order_id)`) to ensure exactly-once database semantics despite at-least-once message delivery.
5. **Distributed Tracing (AWS X-Ray):** Active tracing passes context from API Gateway through SQS down to DynamoDB writes for complete latency observability.

---

## 📁 Repository Structure

```text
├── .github/
│   └── workflows/
│       └── serverless-ci.yaml   # Unit testing, Bandit SAST security audit, Terraform validation
├── src/
│   ├── producer.py              # API Gateway -> SQS Producer Lambda with validation
│   └── consumer.py              # SQS -> DynamoDB Consumer with partial batch failure handling
├── events/
│   └── sample_order_event.json  # Sample API Gateway event payload
├── terraform/
│   ├── versions.tf              # AWS provider ~> 5.40 and Archive provider
│   ├── variables.tf             # Configurable parameters
│   ├── dynamodb.tf              # DynamoDB table with PITR and encryption
│   ├── sqs.tf                   # Primary SQS queue, DLQ, and redrive policies
│   ├── iam.tf                   # Least-privilege IAM roles and policies
│   ├── lambda.tf                # Lambda functions with X-Ray tracing and SQS event mapping
│   ├── api_gateway.tf           # HTTP API Gateway v2, routes, and CORS configuration
│   ├── alarms.tf                # CloudWatch alarms for DLQ depth and Lambda errors
│   ├── outputs.tf               # Public endpoints, queue URLs, and table ARNs
│   └── terraform.tfvars.example # Example variable definitions
├── tests/
│   └── test_lambdas.py          # Pytest unit tests verifying validation and error handling
└── docs/
    ├── architecture.md          # Event-driven pattern specifications and tracing breakdown
    └── deployment-guide.md      # AWS deployment, curl testing, and cleanup guide
```

---

## ⚡ Local Testing

```bash
# Install dependencies
pip install -r requirements.txt

# Run automated tests
pytest tests/ -v
```

---

## ☁️ Cloud Deployment via Terraform

```bash
cd terraform

# 1. Initialize providers
terraform init

# 2. Plan and apply
terraform plan -out=tfplan
terraform apply tfplan
```

### Submit a Test Order:
```bash
curl -X POST https://<API_ENDPOINT>/orders \
  -H "Content-Type: application/json" \
  -d '{"customer_id": "cust_123", "amount": 99.50, "currency": "USD"}'
```

---

## 📄 License
This project is open-source under the [MIT License](LICENSE).
