# ingestion/main.py
"""
Main ingestion script — called by Airflow DAG.
Run manually: python ingestion/main.py
"""

import os
from dotenv import load_dotenv
from hf_api_client import fetch_models, fetch_datasets, add_ingestion_metadata
from s3_uploader import upload_to_s3

load_dotenv()  # Load .env file into os.environ

BUCKET = os.environ["S3_BUCKET_NAME"]

def ingest_models():
    """Full pipeline: fetch -> enrich -> upload for models."""
    models = fetch_models(limit=1000)
    models = add_ingestion_metadata(models, source="huggingface_api_models")
    path = upload_to_s3(models, BUCKET, "bronze/hf_models", "hf_models")
    return path

def ingest_datasets():
    """Full pipeline for datasets."""
    datasets = fetch_datasets(limit=500)
    datasets = add_ingestion_metadata(datasets, source="huggingface_api_datasets")
    path = upload_to_s3(datasets, BUCKET, "bronze/hf_datasets", "hf_datasets")
    return path

if __name__ == "__main__":
    print("🚀 Starting HuggingFace ingestion pipeline...")
    model_path = ingest_models()
    dataset_path = ingest_datasets()
    print(f"✅ Done! Models: {model_path}")
    print(f"✅ Done! Datasets: {dataset_path}")