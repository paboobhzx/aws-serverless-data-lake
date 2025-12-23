provider "aws" { region = "us-east-1"}

#S3 Buckets
resource "aws_s3_bucket" "raw_bucket" {
    bucket = "pablo-datalake-raw-${random_id.suffix.hex}"
    force_destroy = true
}

resource "aws_s3_bucket" "clean_bucket" {
    bucket = "pablo-datalake-clean-${random_id.suffix.hex}"
    force_destroy = true
}
resource "random_id" "suffix" { byte_length = 4}

#ECR Repository
resource "aws_ecr_repository" "etl_repo" {
    name = "serverless-etl-processor"
    image_tag_mutability = "MUTABLE"
    force_delete = true
}
#IAM Role and Policy
resource "aws_iam_role" "lambda_role" {
    name = "serverless_etl_role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{ 
            Action = "sts:AssumeRole",
            Effect = "Allow",
            Principal = { 
                Service = "lambda.amazonaws.com"
            }
        }]
    })
}

resource "aws_iam_role_policy" "lambda_policy" {
    name = "serverless_etl_policy"
    role = aws_iam_role.lambda_role.id 
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow",
            Action = ["s3:*", "logs:*"], Resource = "*"
        }]
    })
}
#lambda function
resource "aws_lambda_function" "etl" {
    function_name = "serverless_etl_processor"
    role = aws_iam_role.lambda_role.arn 
    package_type = "Image"
    image_uri = "${aws_ecr_repository.etl_repo.repository_url}:latest"
    timeout = 60
    memory_size = 512
    lifecycle  {
    ignore_changes = [image_uri]
    }
}

#s3 trigger
resource "aws_s3_bucket_notification" "bucket_notification" {
    bucket = aws_s3_bucket.raw_bucket.id 
    lambda_function {
        lambda_function_arn = aws_lambda_function.etl.arn 
        events = ["s3:ObjectCreated:*"]
        filter_suffix = ".csv"
        
    }
    depends_on = [aws_lambda_permission.allow_s3]
}

resource "aws_lambda_permission" "allow_s3" {
    statement_id = "AllowExecutionFromS3"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.etl.function_name
    principal = "s3.amazonaws.com"
    source_arn = aws_s3_bucket.raw_bucket.arn 
}
terraform { 
    backend "s3" {
        bucket = "pablo-tf-state-backend-732"
        key = "serverless-data-lake/terraform.tfstate"
        region = "us-east-1"
    }
}
#Outputs
output "ecr_repo_url" { value = aws_ecr_repository.etl_repo.repository_url }
output "raw_bucket_name" { value = aws_s3_bucket.raw_bucket.id}
#Data Transformation Steps and resources
#AWS Glue Data Catalog
resource "aws_glue_catalog_database" "datalake_db" {
    name = "pablo_datalake_db"
}
#AWS Glue Crawler (discover the schema)
resource "aws_glue_crawler" "datalake_crawler" {
    name = "pablo_sales_crawler"
    database_name = aws_glue_catalog_database.datalake_db.name 
    role = aws_iam_role.glue_role.arn 

    s3_target {
        path = "s3://${aws_s3_bucket.clean_bucket.id}/"
    }
}
#IAM Role for Glue
resource "aws_iam_role" "glue_role" {
    name = "serverless_glue_role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{ 
            Action = "sts:AssumeRole",
            Effect = "Allow",
            Principal = { Service = "glue.amazonaws.com"}
        }]
    })
}

resource "aws_iam_role_policy" "glue_policy" {
    name = "serverless_glue_policy"
    role = aws_iam_role.glue_role.id 
    policy = jsonencode({ 
        Version = "2012-10-17"
        Statement = [{ 
            Effect = "Allow",
            Actions = ["s3:GetObject", "s3:ListBucket"],
            Resource = [ 
                aws_s3_bucket.clean_bucket.arn ,
                "${aws_s3_bucket.clean_bucket.arn}/*"
            ]
        }, {
            Effect = "Allow",
            Action = ["glue:*", "logs:*"],
            Resource = "*"
        }]
    })
}