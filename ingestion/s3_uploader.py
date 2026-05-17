# ingestion/s3_uploader.py
"""
Upload raw JSON data to AWS S3 with partitioned paths.
Partitioning by year/month/day enables faster Snowflake queries
and keeps costs low (Athena/Snowflake scan less data).
"""

import boto3
import json
import os
from datetime import datetime

def get_s3_client():
    """Create S3 client using environment variables."""
    return boto3.client(
        "s3",
        aws_access_key_id=os.environ["AWS_ACCESS_KEY_ID"],
        aws_secret_access_key=os.environ["AWS_SECRET_ACCESS_KEY"],
        region_name=os.environ.get("AWS_REGION", "us-east-1")
    )

def upload_to_s3(
    data: list[dict],
    bucket: str,
    prefix: str,           # e.g. "bronze/hf_models"
    filename_prefix: str   # e.g. "hf_models"
) -> str:
    """
    Upload JSON data to S3 with date partitioning.
    
    Final S3 path: 
    s3://bucket/bronze/hf_models/year=2024/month=01/day=15/hf_models_20240115_120000.json
    """
    client = get_s3_client()
    now = datetime.utcnow()
    
    # Build partitioned S3 key (path)
    # This Hive-style partitioning (key=value) is understood by
    # Athena, Spark, and Snowflake external stages automatically
    s3_key = (
        f"{prefix}/"
        f"year={now.strftime('%Y')}/"
        f"month={now.strftime('%m')}/"
        f"day={now.strftime('%d')}/"
        f"{filename_prefix}_{now.strftime('%Y%m%d_%H%M%S')}.json"
    )
    
    # Convert list to JSON Lines format (one JSON object per line)
    # JSONL is preferred in data engineering — easier to stream and parse
    json_lines = "\n".join(json.dumps(record) for record in data)
    
    client.put_object(
        Bucket=bucket,
        Key=s3_key,
        Body=json_lines.encode("utf-8"),
        ContentType="application/json"
    )
    
    full_path = f"s3://{bucket}/{s3_key}"
    print(f"✅ Uploaded {len(data)} records to {full_path}")
    return full_path