import os
import sys
import uuid
import logging
from pathlib import Path
from typing import List, Dict, Any, Optional
from dotenv import load_dotenv
import google.generativeai as genai
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct

# Configure robust structured logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger("ClinicalGuidelineIngestion")

# Resolve absolute pathing to prevent CWD variance
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
load_dotenv(PROJECT_ROOT / ".env")

QDRANT_PATH = os.getenv("QDRANT_PATH", str(PROJECT_ROOT / "local_qdrant_data"))
COLLECTION_NAME = "clinical_guidelines"
EMBEDDING_MODEL = "models/text-embedding-004"
VECTOR_DIMENSION = 768

# Comprehensive Population Health SOPs for Closing the Screening-to-Care Loop
SAMPLE_CLINICAL_GUIDELINES = """
=== SECTION: SOP-001 - HIGH-RISK SUSPECTED MELANOMA & INVASIVE MALIGNANCY (PATHWAY A) ===
1. Scope and Eligibility:
Applies to adult and pediatric patients screened via on-device edge CNN where the malignant risk vector probability is >= 0.60, or where symptoms demonstrate rapid morphological evolution within <= 30 days (such as ulceration, bleeding, asymmetrical edge spread, or rapid pigmentation change).

2. Recommended Clinical Action:
Immediate 'Urgent Dermatology Referral' under the Rapid 2-Week-Wait (2WW) Suspected Skin Cancer Pathway.
Direct booking into secondary care fast-track dermoscopy clinic or urgent surgical excision biopsy clinic.

3. Actionable Timeframe:
Timeframe: 2 to 14 days maximum. In cases of spontaneous bleeding or documented rapid elevation within the past 14 days, prioritize scheduling within <= 7 days.

4. Closed-Loop Care Navigation & Safety-Netting:
- Mandatory Human Verification: An accredited population health care navigator and licensed clinician must review and sign off within 24 hours.
- Direct Outreach: Two automated SMS notifications accompanied by a direct phone call from the navigation hub within 48 hours to secure specialist appointment booking.
- Escalation: If uncontactable after 72 hours, alert primary care provider for welfare contact.

=== SECTION: SOP-002 - MODERATE-RISK ATYPICAL NEVI & DYSPLASTIC LESIONS (PATHWAY B) ===
1. Scope and Eligibility:
Applies to lesions with intermediate edge malignancy risk probabilities (between 0.20 and 0.59), or lesions with gradual persistent changes over > 30 days without frank ulceration, or patients with multiple dysplastic nevi.

2. Recommended Clinical Action:
'Routine Dermatology Referral' or 'Store-and-Forward Teledermatology Triage'.
High-resolution polarized dermoscopic imaging should be captured by a community screening practitioner or general practitioner and transmitted for asynchronous secondary dermatologist review.

3. Actionable Timeframe:
Timeframe: 14 to 30 days.

4. Closed-Loop Care Navigation & Safety-Netting:
- Digital Monitoring Instructions: Patient is provided with standardized digital lesion self-monitoring guidelines (ABCDE criteria checklist).
- Digital Safety Net: Automated follow-up prompt sent at day 21 if secondary teledermatology review has not yet been logged.
- Requires clinician review prior to diagnostic discharge.

=== SECTION: SOP-003 - LOW-RISK BENIGN SEBORRHEIC & MELANOCYTIC LESIONS (PATHWAY C) ===
1. Scope and Eligibility:
Applies to lesions exhibiting high benign probability (>= 0.85, malignant probability < 0.15) with stable clinical presentation (> 90 days symptom duration without growth, bleed, or itch), consistent with benign nevus, seborrheic keratosis, or dermatofibroma.

2. Recommended Clinical Action:
'Routine Primary Care Observation & Patient Reassurance'.
No urgent secondary care referral required. Recommend routine skin checks during annual physical or primary care wellness visits.

3. Actionable Timeframe:
Timeframe: 90 to 365 days (Periodic/Annual Screening).

4. Closed-Loop Care Navigation & Safety-Netting:
- Educational Navigation: Automated dispatch of validated patient self-examination educational modules.
- Re-screening Trigger: Patient instructed to re-screen immediately if ABCDE danger signs emerge (Asymmetry, Border irregularity, Color changes, Diameter > 6mm, or Evolution).
- Requires clinician sign-off in the Electronic Health Record (EHR) to close loop.

=== SECTION: SOP-004 - DOMAIN SHIFT & EDGE SENSOR QUALITY DEGRADATION (PATHWAY D) ===
1. Scope and Eligibility:
Triggered whenever the on-device EdgeRiskVector flags 'domain_shift_detected = True'. Indicates poor illumination, motion artifact, optical blur, sub-optimal focal length, or extreme skin pigmentation out-of-distribution with CNN training benchmarks.

2. Recommended Clinical Action:
'In-Person Clinical Skin Examination & Standardized Re-imaging'.
Algorithmic risk score cannot be guaranteed. The algorithmic prediction must not be used to rule out disease.

3. Actionable Timeframe:
Timeframe: 7 to 14 days.

4. Closed-Loop Care Navigation & Safety-Netting:
- Automated flag routed to community health worker or primary care team to perform supervised dermoscopy under standardized polarized lighting.
- Human clinician physical inspection is mandatory.

=== SECTION: SOP-005 - HIGH-RISK COMORBIDITY & IMMUNOSUPPRESSION OVERLAY (PATHWAY E) ===
1. Scope and Eligibility:
Applies to patients with flagged comorbidities such as organ transplant recipient, immunosuppressive/biologic therapy, personal history of melanoma, or genetic cancer syndromes (e.g., CDKN2A mutation), regardless of edge probability score.

2. Recommended Clinical Action:
'Expedited Specialized High-Risk Dermatology Consultation'.
Immunosuppressed patients have a markedly accelerated progression rate for non-melanoma and melanoma skin malignancies.

3. Actionable Timeframe:
Timeframe: 7 to 14 days.

4. Closed-Loop Care Navigation & Safety-Netting:
- Overrides low-risk algorithmic classifications to ensure aggressive surveillance.
- Mandatory physician review within 48 hours.
"""


def chunk_text(
    raw_text: str,
    chunk_size: int = 600,
    chunk_overlap: int = 100
) -> List[Dict[str, Any]]:
    """
    Chunks clinical text documents on paragraph/section boundaries while maintaining
    sliding window token/character overlap to preserve clinical context across boundaries.
    """
    sections = raw_text.strip().split("=== SECTION: ")
    chunks: List[Dict[str, Any]] = []

    for section in sections:
        section = section.strip()
        if not section:
            continue

        lines = section.split("\n", 1)
        header = lines[0].replace(" ===", "").strip()
        body = lines[1].strip() if len(lines) > 1 else lines[0].strip()

        paragraphs = [p.strip() for p in body.split("\n\n") if p.strip()]
        current_chunk = f"Section: {header}\n"

        for p in paragraphs:
            if len(current_chunk) + len(p) <= chunk_size:
                current_chunk += f"\n{p}"
            else:
                chunks.append({
                    "section_title": header,
                    "text": current_chunk.strip()
                })
                overlap_text = current_chunk[-chunk_overlap:] if len(current_chunk) > chunk_overlap else ""
                current_chunk = f"Section: {header} (Continued)\n{overlap_text}\n{p}"

        if current_chunk.strip():
            chunks.append({
                "section_title": header,
                "text": current_chunk.strip()
            })

    logger.info("Successfully chunked clinical text into %d discrete chunks.", len(chunks))
    return chunks


def init_qdrant_collection(client: QdrantClient) -> None:
    """Ensures the Qdrant clinical guidelines collection exists with 768-dim cosine metrics."""
    try:
        if not client.collection_exists(collection_name=COLLECTION_NAME):
            logger.info("Collection '%s' does not exist. Creating new collection...", COLLECTION_NAME)
            client.create_collection(
                collection_name=COLLECTION_NAME,
                vectors_config=VectorParams(size=VECTOR_DIMENSION, distance=Distance.COSINE),
            )
            logger.info("Collection '%s' created successfully (dimension=%d).", COLLECTION_NAME, VECTOR_DIMENSION)
        else:
            logger.info("Target collection '%s' already exists in Qdrant.", COLLECTION_NAME)
    except Exception as exc:
        logger.error("Failed to initialize Qdrant collection: %s", exc)
        raise


def embed_text_batch(texts: List[str]) -> List[List[float]]:
    """
    Generates 768-dimensional document embeddings using Gemini embedding models.
    Supports models/text-embedding-004 and models/gemini-embedding-001 with output_dimensionality=768.
    """
    load_dotenv(PROJECT_ROOT / ".env", override=True)
    api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
    if not api_key:
        raise ValueError(
            "GEMINI_API_KEY or GOOGLE_API_KEY environment variable is not configured. "
            "Please configure your Gemini API key in the .env file."
        )

    genai.configure(api_key=api_key, transport="rest")
    candidate_models = [
        "models/gemini-embedding-001",
        "models/text-embedding-004",
    ]

    embeddings: List[List[float]] = []

    for idx, text in enumerate(texts):
        embedding = None
        last_err = None

        for model_name in candidate_models:
            try:
                res = genai.embed_content(
                    model=model_name,
                    content=text,
                    task_type="retrieval_document",
                    title="Clinical Guideline SOP",
                    output_dimensionality=VECTOR_DIMENSION,
                )
                embedding = res["embedding"]
                break
            except Exception as exc:
                last_err = exc
                if "not found" in str(exc).lower() or "404" in str(exc):
                    continue
                logger.warning("Error with model %s: %s", model_name, exc)

        if embedding is None:
            raise RuntimeError(f"Failed to generate embedding for chunk {idx}: {last_err}")

        embeddings.append(embedding)
        logger.debug("Generated embedding for chunk %d/%d", idx + 1, len(texts))

    return embeddings


def ingest_guidelines(client: Optional[QdrantClient] = None) -> int:
    """
    Main ingestion execution pipeline:
    1. Parse and chunk clinical operating procedures.
    2. Embed chunks into 768-dim vectors via Gemini embedding model.
    3. Upsert payloads and vectors into local Qdrant collection.

    Accepts an existing QdrantClient instance to avoid file-lock conflicts
    when executed in-process alongside the FastAPI server.
    """
    logger.info("Starting clinical guidelines ingestion pipeline...")

    # 1. Acquire or initialize Qdrant client
    if client is None:
        logger.info("Opening local Qdrant database at: %s", QDRANT_PATH)
        try:
            client = QdrantClient(path=QDRANT_PATH)
        except RuntimeError as lock_err:
            if "already accessed by another instance" in str(lock_err):
                logger.error(
                    "Local Qdrant database is currently locked by another active process "
                    "(such as the running Uvicorn server). Either stop Uvicorn temporarily, "
                    "or trigger ingestion via the FastAPI '/api/v1/admin/ingest' endpoint."
                )
            raise
    else:
        logger.info("Reusing existing Qdrant client instance (in-process execution).")

    init_qdrant_collection(client)

    # 2. Chunk text
    chunks = chunk_text(SAMPLE_CLINICAL_GUIDELINES)
    texts = [c["text"] for c in chunks]

    # 3. Generate Embeddings
    logger.info("Requesting embeddings from %s for %d chunks...", EMBEDDING_MODEL, len(texts))
    vectors = embed_text_batch(texts)

    # 4. Construct PointStructs
    points: List[PointStruct] = []
    for idx, (chunk_info, vector) in enumerate(zip(chunks, vectors)):
        # Deterministic UUID guarantees idempotent re-indexing
        point_id = str(uuid.uuid5(uuid.NAMESPACE_DNS, chunk_info["text"]))
        point = PointStruct(
            id=point_id,
            vector=vector,
            payload={
                "section_title": chunk_info["section_title"],
                "text": chunk_info["text"],
                "source": "Future Health Population Triage Guidelines",
                "chunk_index": idx,
            }
        )
        points.append(point)

    # 5. Upsert to Qdrant
    logger.info("Upserting %d points into Qdrant collection '%s'...", len(points), COLLECTION_NAME)
    client.upsert(collection_name=COLLECTION_NAME, points=points)
    
    count_info = client.count(collection_name=COLLECTION_NAME)
    logger.info(
        "Ingestion complete! Collection '%s' contains %d total points.",
        COLLECTION_NAME,
        count_info.count
    )
    return count_info.count


if __name__ == "__main__":
    try:
        total = ingest_guidelines()
        print(f"\nSUCCESS: Indexed {total} clinical guideline vectors into Qdrant.")
    except Exception as e:
        logger.exception("Critical ingestion failure: %s", e)
        sys.exit(1)
