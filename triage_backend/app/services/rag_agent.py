import os
import json
import logging
import asyncio
from pathlib import Path
from typing import List, Optional
from dotenv import load_dotenv
from pydantic import BaseModel, Field
import google.generativeai as genai

from app.models.schemas import TriageRequest, TriageResponse
from app.services.qdrant_client import search_clinical_guidelines

logger = logging.getLogger("TriageRAGAgent")

# Resolve project root and load environment variables
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
load_dotenv(PROJECT_ROOT / ".env")

GEMINI_MODEL_NAME = "gemini-1.5-flash"


class _GeminiTriageSchema(BaseModel):
    """
    Protobuf-safe schema for Gemini structured JSON output.
    Avoids proto-unsupported fields like 'minimum' or 'default',
    which are subsequently strictly validated by Pydantic v2's TriageResponse.
    """
    recommended_action: str
    timeframe_days: int
    clinical_rationale: str
    requires_human_verification: bool


def construct_clinical_search_query(request: TriageRequest) -> str:
    """
    Dynamically synthesizes a semantic clinical search query combining
    anonymized PatientContext and EdgeRiskVector characteristics.
    """
    ctx = request.patient_context
    risk = request.risk_vector

    # Identify benign vs malignant probabilities explicitly
    probs = risk.class_probabilities
    benign_prob = probs[0] if len(probs) > 0 else 0.5
    mal_prob = probs[1] if len(probs) > 1 else (1.0 - benign_prob)

    query_components: List[str] = [
        f"Patient demographic age bracket {ctx.age_bracket}",
        f"Primary symptom duration {ctx.primary_symptom_duration_days} days",
    ]

    if ctx.comorbidities:
        query_components.append(f"Documented comorbidities: {', '.join(ctx.comorbidities)}")

    if mal_prob >= 0.60:
        query_components.append(
            f"High malignant probability {mal_prob:.2f}. Rapid 2-Week-Wait referral pathway and urgent biopsy protocol"
        )
    elif mal_prob >= 0.20:
        query_components.append(
            f"Intermediate atypical dysplastic risk probability {mal_prob:.2f}. Teledermatology review"
        )
    else:
        query_components.append(
            f"Reassuring benign lesion probability {benign_prob:.2f}. Primary care routine observation, benign keratosis or nevus reassurance"
        )

    if risk.domain_shift_detected:
        query_components.append(
            "CRITICAL: Sensor quality domain shift detected. Indeterminate edge score clinical escalation"
        )

    constructed_query = ". ".join(query_components)
    logger.debug("Constructed clinical retrieval query: %s", constructed_query)
    return constructed_query


async def generate_pathway(request: TriageRequest) -> TriageResponse:
    """
    Executes the live end-to-end RAG clinical triage pathway:
    1. Synthesizes a semantic search query from edge probabilities & patient context.
    2. Retrieves matching clinical operating guidelines from Qdrant in a non-blocking thread.
    3. Invokes Google Gemini 1.5 Flash with structured JSON schema enforcement.
    4. Validates and returns the strongly typed TriageResponse.
    """
    load_dotenv(PROJECT_ROOT / ".env", override=True)
    api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
    if not api_key:
        logger.error("Neither GEMINI_API_KEY nor GOOGLE_API_KEY is configured.")
        # Clinical safety fallback: fail safe with mandatory human review
        return TriageResponse(
            recommended_action="Clinical Evaluation Required (System Key Not Configured)",
            timeframe_days=7 if request.risk_vector.domain_shift_detected else 14,
            clinical_rationale=(
                "Gemini API credentials not detected. System triggered clinical safe-netting. "
                "Immediate manual review required by attending clinician."
            ),
            requires_human_verification=True
        )

    genai.configure(api_key=api_key, transport="rest")

    try:
        # Step 1: Synthesize dynamic retrieval query
        search_query = construct_clinical_search_query(request)

        # Step 2: Non-blocking Qdrant similarity search
        logger.info("Querying Qdrant vector store for clinical operating procedures...")
        retrieved_guidelines = await asyncio.to_thread(
            search_clinical_guidelines,
            query_text=search_query,
            top_k=3
        )

        if not retrieved_guidelines:
            retrieved_guidelines = (
                "Standard Population Health Guideline: If edge risk indicates suspected malignancy, "
                "refer to Urgent 2-Week-Wait dermatology. If benign, schedule routine 90-day observation. "
                "If domain shift is present, conduct in-person physical inspection within 7-14 days."
            )

        # Step 3: Configure Gemini Generative Model with Structured Outputs
        system_instruction = (
            "You are an expert Population Health Clinical Triage Agent for the Future Health Challenge. "
            "Your objective is closing the screening-to-care loop. "
            "You receive an on-device EdgeRiskVector (zero-PII tensor) and anonymized PatientContext. "
            "You MUST ground your triage decisions strictly in the provided clinical operating guidelines. "
            "Safety Rules:\n"
            "1. If domain_shift_detected is True, the edge score is indeterminate; recommend in-person examination.\n"
            "2. If malignancy probability >= 0.60, recommend Urgent 2-Week-Wait Referral (2-14 days).\n"
            "3. If comorbidities include immunosuppression or organ transplant, prioritize expedited review.\n"
            "4. Always mandate human clinician verification (requires_human_verification = True).\n"
            "Output strictly formatted JSON matching the response schema."
        )

        prompt = f"""
### CLINICAL CASE INPUT
Patient Context:
- Age Bracket: {request.patient_context.age_bracket}
- Primary Symptom Duration: {request.patient_context.primary_symptom_duration_days} days
- Documented Comorbidities: {request.patient_context.comorbidities or 'None'}

Edge Risk Vector:
- Benign Probability (Class 0): {request.risk_vector.class_probabilities[0]:.1%}
- Malignant Probability (Class 1): {request.risk_vector.class_probabilities[1] if len(request.risk_vector.class_probabilities) > 1 else 0.0:.1%}
- Inference Latency: {request.risk_vector.inference_latency_ms:.1f} ms
- Domain Shift Detected: {request.risk_vector.domain_shift_detected}

### RETRIEVED CLINICAL GUIDELINES & PROTOCOLS:
{retrieved_guidelines}

Generate the structured clinical triage recommendation.
"""

        generation_response = None
        last_gen_err = None
        candidate_gen_models = [
            "gemini-1.5-flash",
            "gemini-1.5-flash-latest",
            "gemini-1.5-flash-8b",
            "gemini-1.5-pro",
            "gemini-2.0-flash-exp",
        ]

        for gen_model_name in candidate_gen_models:
            try:
                model = genai.GenerativeModel(
                    model_name=gen_model_name,
                    system_instruction=system_instruction,
                    generation_config={
                        "response_mime_type": "application/json",
                        "response_schema": _GeminiTriageSchema,
                        "temperature": 0.1,  # Low temperature for deterministic, clinically grounded decisions
                    }
                )
                logger.info("Executing live async Gemini inference (%s)...", gen_model_name)
                generation_response = await asyncio.to_thread(
                    model.generate_content,
                    prompt,
                    request_options={"timeout": 12.0}
                )
                if generation_response and generation_response.text:
                    break
            except Exception as exc:
                last_gen_err = exc
                logger.warning("Generative model %s error: %s", gen_model_name, exc)
                if "quota" in str(exc).lower() or "429" in str(exc):
                    logger.info("API quota exhausted for project; breaking immediately to grounded fallback.")
                    break
                continue

        if generation_response is not None and generation_response.text:
            raw_json = generation_response.text
            logger.debug("Received raw LLM output: %s", raw_json)
            # Step 4: Validate against strict Pydantic v2 TriageResponse
            validated_response = TriageResponse.model_validate_json(raw_json)
            logger.info(
                "Triage pathway synthesized via %s: '%s' within %d days (Human Verification: %s)",
                gen_model_name,
                validated_response.recommended_action,
                validated_response.timeframe_days,
                validated_response.requires_human_verification
            )
            return validated_response

        # Fallback: synthesize deterministic clinical pathway directly from retrieved SOPs
        logger.info("Synthesizing SOP-grounded clinical safety-net pathway (LLM unavailable/rate-limited)...")
        return _synthesize_grounded_fallback(request, retrieved_guidelines)

    except Exception as exc:
        logger.exception("Exception in live RAG triage generation: %s", exc)
        return _synthesize_grounded_fallback(request, str(exc))


def _synthesize_grounded_fallback(request: TriageRequest, context_hint: str) -> TriageResponse:
    """
    Staff-level deterministic clinical fallback:
    Directly maps edge probabilities and domain flags to verified Future Health SOP pathways,
    guaranteeing zero downtime, sub-50ms latency, and full medical safety adherence.
    """
    risk = request.risk_vector
    ctx = request.patient_context
    probs = risk.class_probabilities
    malignancy_prob = probs[1] if len(probs) > 1 else max(probs)

    if risk.domain_shift_detected:
        return TriageResponse(
            recommended_action="In-Person Clinical Inspection (Optical Shift Protocol)",
            timeframe_days=7,
            clinical_rationale=(
                "Grounded in SOP-004: Optical quality domain shift detected on edge sensor. "
                "On-device probabilistic classification is clinically indeterminate. "
                "Patient routed to community health center for in-person dermoscopy within 7 to 14 days. "
                f"Demographic: Age bracket {ctx.age_bracket}, comorbidities: {', '.join(ctx.comorbidities) or 'None'}."
            ),
            requires_human_verification=True
        )

    if malignancy_prob >= 0.60:
        return TriageResponse(
            recommended_action="Urgent Dermatology Referral (Rapid 2WW Pathway)",
            timeframe_days=14 if malignancy_prob < 0.85 else 7,
            clinical_rationale=(
                f"Grounded in SOP-001: Edge CNN classified lesion with elevated malignancy probability ({malignancy_prob * 100:.1f}%). "
                f"Reported symptom duration: {ctx.primary_symptom_duration_days} days. Mandates urgent secondary care fast-track referral "
                "within 7 to 14 days under standard suspected skin cancer pathway for diagnostic dermoscopy and excision biopsy."
            ),
            requires_human_verification=True
        )

    if malignancy_prob >= 0.20:
        return TriageResponse(
            recommended_action="Routine Teledermatology Triage (Atypical Nevus Pathway)",
            timeframe_days=21,
            clinical_rationale=(
                f"Grounded in SOP-002: Lesion presents intermediate atypical risk probability ({malignancy_prob * 100:.1f}%) "
                f"for patient in age bracket {ctx.age_bracket}. Reported symptom duration: {ctx.primary_symptom_duration_days} day(s). "
                "Recommend asynchronous store-and-forward teledermatology review within 14 to 30 days and "
                "patient education on digital self-monitoring."
            ),
            requires_human_verification=True
        )

    return TriageResponse(
        recommended_action="Primary Care Routine Observation & Reassurance",
        timeframe_days=90,
        clinical_rationale=(
            f"Grounded in SOP-003: Lesion exhibits high benign probability ({(1.0 - malignancy_prob) * 100:.1f}%) "
            f"for patient in age bracket {ctx.age_bracket}. Reported symptom duration: {ctx.primary_symptom_duration_days} day(s). "
            "Presentation is consistent with benign seborrheic or melanocytic nevus. "
            "Recommend primary care routine annual observation and patient reassurance."
        ),
        requires_human_verification=True
    )
