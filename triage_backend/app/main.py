import asyncio
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from app.models.schemas import TriageRequest, TriageResponse
from app.services import rag_agent

app = FastAPI(
    title="Future Health Triage API",
    version="1.0.0",
    description="Privacy-first agentic triage backend for the Future Health Challenge."
)

# Configure CORS for edge client communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict this to your specific client domains/IPs
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
@app.get("/healthz")
async def health_check():
    """Simple health check endpoint to verify the server is running."""
    return {"status": "healthy", "service": "Triage API"}

@app.post("/api/v1/triage", response_model=TriageResponse)
async def process_triage(request: TriageRequest):
    """
    Ingests edge probabilities and patient context, then returns structured clinical navigation
    generated via live Qdrant RAG retrieval and Google Gemini reasoning.
    """
    try:
        response = await rag_agent.generate_pathway(request)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/admin/ingest")
async def trigger_ingestion():
    """
    Admin endpoint to trigger indexing of clinical guidelines into Qdrant in-process,
    avoiding file-lock contention with the running ASGI server.
    """
    from app.services.ingest_guidelines import ingest_guidelines
    from app.services.qdrant_client import qdrant_db
    try:
        count = await asyncio.to_thread(ingest_guidelines, qdrant_db)
        return {
            "status": "success",
            "message": f"Successfully ingested {count} clinical guideline chunks into Qdrant."
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))