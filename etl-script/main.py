import pandas as pd
import boto3
import os
import io
#initializing S3 Client
s3_client = boto3.client("s3")
def lambda_handler(event, context):
    print("CI/CD Deployment: Starting ETL Lambda")
    #Get bucket and file name from the 'Event'(the trigger) 
    
    try:
        source_bucket = event['Records'][0]['s3']['bucket']['name']
        source_key = event['Records'][0]['s3']['object']['key']
        print(f"New file detected: s3://{source_bucket}/{source_key}")
    except KeyError:
        #fallback for manual testing
        print("No S3 event found. Running in test mode")
        return {"status": "skipped", "reason": "No S3 Event"}
    #Read file from S3 to memory
    response = s3_client.get_object(Bucket=source_bucket, Key=source_key)
    csv_content = response['Body'].read()
    #Load into Pandas
    df = pd.read_csv(io.BytesIO(csv_content))
    #TRANSFORM
    df['date'] = pd.to_datetime(df['date'])
    df['total_value'] = df['quantity'] * df['price']
    high_value_df = df[df['total_value'] > 50]

    print(f"Processed {len(high_value_df)} high-value rows")
    #Save back to S3 
    destination_bucket = source_bucket.replace('raw', 'clean')
    destination_key = source_key.replace (".csv", ".parquet")
    #Convert to parquet in memory buffer
    parquet_buffer = io.BytesIO()
    high_value_df.to_parquet(parquet_buffer, index = False)
    #Upload to the clean bucket
    print(f"Uploading to: s3://{destination_bucket}/{destination_key}")
    s3_client.put_object(
        Bucket = destination_bucket,
        Key = destination_key,
        Body = parquet_buffer.getvalue()
    )
    return { 
        'statusCode': 200,
        'body': f"Success! Processed {source_key}"
    }