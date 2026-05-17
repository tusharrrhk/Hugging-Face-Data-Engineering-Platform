# ingestion/hf_api_client.py
"""
Hugging Face Hub API Client
API Docs: https://huggingface.co/docs/hub/api
No authentication needed for public data!
"""

import requests
import json
import logging
from datetime import datetime
from typing import Optional

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

BASE_URL = "https://huggingface.co/api"

def fetch_models(
    limit: int = 1000,
    sort: str = "downloads",         # Sort by most downloaded
    direction: int = -1,              # -1 = descending
    filter_tag: Optional[str] = None  # e.g. "text-classification"
) -> list[dict]:
    """
    Fetch models from HuggingFace Hub API.
    
    Returns list of model metadata including:
    - modelId, author, downloads, likes
    - pipeline_tag (the task type)
    - library_name (pytorch, tensorflow, etc.)
    - tags, createdAt, lastModified
    """
    params = {
        "limit": limit,
        "sort": sort,
        "direction": direction,
        "full": "true",          # Get full metadata
        "config": "true"         # Include model config
    }
    if filter_tag:
        params["filter"] = filter_tag

    logger.info(f"Fetching {limit} models from HuggingFace API...")
    
    response = requests.get(
        f"{BASE_URL}/models",
        params=params,
        timeout=60
    )
    response.raise_for_status()  # Raise error if HTTP 4xx/5xx
    
    models = response.json()
    logger.info(f"✅ Fetched {len(models)} models")
    return models


def fetch_datasets(limit: int = 500) -> list[dict]:
    """Fetch datasets from HuggingFace Hub API."""
    params = {
        "limit": limit,
        "sort": "downloads",
        "direction": -1,
        "full": "true"
    }
    
    logger.info(f"Fetching {limit} datasets from HuggingFace API...")
    response = requests.get(f"{BASE_URL}/datasets", params=params, timeout=60)
    response.raise_for_status()
    
    datasets = response.json()
    logger.info(f"✅ Fetched {len(datasets)} datasets")
    return datasets


def add_ingestion_metadata(records: list[dict], source: str) -> list[dict]:
    """
    Add metadata to each record before saving.
    This is a Data Engineering best practice — always track
    WHERE and WHEN data came from.
    """
    ingested_at = datetime.utcnow().isoformat()
    
    for record in records:
        record["_ingested_at"] = ingested_at
        record["_source"] = source
    
    return records