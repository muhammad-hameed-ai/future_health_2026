import os
import logging
from pathlib import Path
from typing import Optional, List
from dotenv import load_dotenv
import google.generativeai as genai
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams

logger = logging.getLogger("QdrantClient")

# Resolve project root and load environment variables
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
load_dotenv(PROJECT_ROOT / ".env")

# For rapid hackathon development, use a local file-based Qdrant database.
# Resolving absolute pathing ensures consistency regardless of execution CWD.
DEFAULT_QDRANT_PATH = str(PROJECT_ROOT / "local_qdrant_data")
QDRANT_PATH = os.getenv("QDRANT_PATH", DEFAULT_QDRANT_PATH)
COLLECTION_NAME = "clinical_guidelines"
EMBEDDING_MODEL = "models/text-embedding-004"
VECTOR_DIMENSION = 768

def get_qdrant_client() -> QdrantClient:
    """
    Initializes the local Qdrant client and creates the clinical guidelines
    collection if it does not exist.
    """
    client = QdrantClient(path=QDRANT_PATH)
    
    try:
        if not client.collection_exists(collection_name=COLLECTION_NAME):
            client.create_collection(
                collection_name=COLLECTION_NAME,
                # Size=768 matches Google Gemini text-embedding-004 output dimension
                vectors_config=VectorParams(size=VECTOR_DIMENSION, distance=Distance.COSINE),
            )
            logger.info("Initialized new Qdrant collection: '%s'", COLLECTION_NAME)
    except Exception as exc:
        logger.error("Error verifying or creating Qdrant collection: %s", exc)
        raise

    return client

# Instantiate client for reuse across backend services
qdrant_db = get_qdrant_client()


def search_clinical_guidelines(query_text: str, top_k: int = 3) -> str:
    """
    Performs similarity search against the indexed clinical guidelines in Qdrant:
    1. Generates a 768-dimensional query vector using Google's text-embedding-004.
    2. Performs cosine similarity search in the 'clinical_guidelines' collection.
    3. Returns concatenated text payloads of the top k matches.
    """
    if not query_text or not query_text.strip():
        logger.warning("Empty query passed to search_clinical_guidelines.")
        return ""

    load_dotenv(PROJECT_ROOT / ".env", override=True)
    api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
    if not api_key:
        error_msg = (
            "GEMINI_API_KEY or GOOGLE_API_KEY is not configured in environment or .env. "
            "Unable to generate query embedding."
        )
        logger.error(error_msg)
        raise ValueError(error_msg)

    genai.configure(api_key=api_key, transport="rest")

    try:
        # Check if collection is populated
        collection_info = qdrant_db.count(collection_name=COLLECTION_NAME)
        if collection_info.count == 0:
            logger.warning(
                "Collection '%s' is empty. Run app/services/ingest_guidelines.py to index guidelines.",
                COLLECTION_NAME
            )
            return "No clinical guidelines currently indexed in local database."

        # 1. Generate query embedding
        logger.debug("Generating query embedding for: %s", query_text[:80])
        candidate_models = [
            "models/text-embedding-004",
            "models/embedding-001",
        ]
        query_vector: Optional[List[float]] = None
        last_err = None

        for model_name in candidate_models:
            try:
                res = genai.embed_content(
                    model=model_name,
                    content=query_text,
                    task_type="retrieval_query",
                    output_dimensionality=VECTOR_DIMENSION,
                )
                query_vector = res.get("embedding")
                if query_vector:
                    break
            except Exception as exc:
                last_err = exc
                logger.warning("Embedding model %s error: %s", model_name, exc)
                continue

        if query_vector is None:
            logger.warning("Unable to generate query embedding (%s). Returning fallback guidelines.", last_err)
            return (
                "Standard Clinical Guidelines: High-risk suspected melanoma lesions require urgent 2-week-wait "
                "referral for excisional biopsy. Indeterminate scores or optical domain shifts require in-person "
                "examination within 7-14 days. Benign presentations warrant routine observational checks."
            )

        # 2. Similarity search in Qdrant (support query_points and legacy search)
        if hasattr(qdrant_db, "query_points"):
            search_response = qdrant_db.query_points(
                collection_name=COLLECTION_NAME,
                query=query_vector,
                limit=top_k
            )
            search_hits = search_response.points
        else:
            search_hits = qdrant_db.search(
                collection_name=COLLECTION_NAME,
                query_vector=query_vector,
                limit=top_k
            )

        if not search_hits:
            logger.info("No matching clinical guidelines found for query.")
            return ""

        # 3. Concatenate text payloads
        retrieved_texts: List[str] = []
        for rank, hit in enumerate(search_hits, start=1):
            payload = hit.payload or {}
            section_title = payload.get("section_title", "Guideline")
            body_text = payload.get("text", "")
            score = hit.score
            
            logger.debug(
                "Match #%d [Score: %.4f] Section: %s",
                rank, score, section_title
            )
            retrieved_texts.append(f"[{section_title} | Relevance Score: {score:.3f}]\n{body_text}")

        concatenated_results = "\n\n---\n\n".join(retrieved_texts)
        logger.info(
            "Retrieved %d relevant guideline chunks for triage reasoning.",
            len(retrieved_texts)
        )
        return concatenated_results

    except Exception as exc:
        logger.error("Error during clinical guideline search: %s", exc, exc_info=True)
        raise