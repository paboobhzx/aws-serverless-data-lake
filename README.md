# 💧 AWS Serverless Data Lake & ETL Pipeline

![AWS](https://img.shields.io/badge/AWS-Serverless-orange)
![Terraform](https://img.shields.io/badge/Infrastructure-Terraform-purple)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-blue)
![Python](https://img.shields.io/badge/ETL-Python%20%2B%20Pandas-yellow)

An end-to-end **Data Engineering project** that automates the ingestion, transformation, and analysis of data using **AWS Serverless** technologies.

This project demonstrates a "Lakehouse" architecture where raw data is automatically processed and made queryable via SQL immediately upon arrival.

---

## 🏗️ Architecture
**"From Raw CSV to SQL in Seconds"**

1.  **Ingest:** Raw CSV files are uploaded to an **Amazon S3** landing zone.
2.  **Trigger:** An S3 Event Notification automatically triggers the ETL process.
3.  **Process:** An **AWS Lambda** function (packaged as a Docker container) cleans the data, calculates metrics, and converts it to **Parquet** format.
4.  **Catalog:** **AWS Glue** scans the processed data to discover the schema and update the Data Catalog.
5.  **Analyze:** **Amazon Athena** allows ad-hoc SQL queries directly against the data in S3.

### 🛠️ Tech Stack
* **Language:** Python 3.11 (Pandas, PyArrow)
* **Infrastructure:** Terraform (Remote Backend on S3)
* **Compute:** AWS Lambda (Containerized to support large libraries)
* **Orchestration:** GitHub Actions (CI/CD)
* **Storage & Analytics:** Amazon S3, AWS Glue, Amazon Athena

---

## 🚀 Key Features
* **Event-Driven Architecture:** No servers to manage. The pipeline runs only when data arrives (Cost: ~$0.00 when idle).
* **Automated CI/CD:** Pushing code to `main` triggers a GitHub Action that updates the infrastructure (Terraform) and redeploys the Lambda code (Docker) automatically.
* **Schema Discovery:** AWS Glue Crawlers automatically detect schema changes in the dataset.
* **Optimized Storage:** Data is converted from CSV to Parquet for 10x faster querying and lower storage costs.

---

## ⚙️ How to Deploy

### Prerequisites
* AWS Credentials configured in GitHub Secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
* Terraform Remote Backend (S3 Bucket) configured in `main.tf`

### Manual Deployment (First Run)
1.  **Bootstrap ECR:**
    ```bash
    cd infrastructure
    terraform init
    terraform apply -target=aws_ecr_repository.etl_repo -auto-approve
    ```
2.  **Push Docker Image:**
    ```bash
    cd ../etl-script
    aws ecr get-login-password | docker login --username AWS --password-stdin <YOUR_ECR_URL>
    docker build --provenance=false -t serverless-etl-processor .
    docker push <YOUR_ECR_URL>:latest
    ```
3.  **Deploy Full Stack:**
    ```bash
    cd ../infrastructure
    terraform apply -auto-approve
    ```

---

## 🔎 How to Use
1.  **Upload Data:** Drop a CSV file into the `raw` S3 bucket.
2.  **Wait:** The pipeline takes ~5-10 seconds to process.
3.  **Query:** Go to Amazon Athena and run:
    ```sql
    SELECT * FROM "pablo_datalake_db"."pablo_datalake_clean_<SUFFIX>"
    WHERE total_value > 50;
    ```

---

## 🧹 Clean Up
To avoid costs, destroy the infrastructure:
```bash
cd infrastructure
terraform destroy -auto-approve
