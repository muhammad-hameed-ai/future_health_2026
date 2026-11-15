import os
import asyncio
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from app.models.schemas import TriageRequest, TriageResponse
from app.services import rag_agent
from app.routers import auth

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB_DIST_DIR = os.path.join(BASE_DIR, "web_dist")
STATIC_DIR = os.path.join(BASE_DIR, "static")

app = FastAPI(
    title="Future Health Triage API & Live Web Portal",
    version="3.1.0",
    description="Privacy-first agentic triage backend & interactive digital portal for the Future Health Challenge 2026."
)

# Configure CORS for edge client communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict this to your specific client domains/IPs
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Authentication & Profile Management Router
app.include_router(auth.router)

# Mount Flutter Web Live Application at /app
if os.path.exists(WEB_DIST_DIR):
    app.mount("/app", StaticFiles(directory=WEB_DIST_DIR, html=True), name="web_app")

# Mount static files (including direct APK downloads)
if os.path.exists(STATIC_DIR):
    app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")

@app.get("/")
async def root():
    """Root landing endpoint providing clinical gateway operational status and endpoints."""
    return {
        "platform": "SkinGuard UAE • Future Health Challenge 2026",
        "service": "Autonomous Cutaneous Lesion Triage Intelligence Gateway & Web App",
        "status": "online",
        "accreditation": "Abu Dhabi DoH & Malaffi HIE Standards Compliance",
        "endpoints": {
            "web_application": "/app",
            "health": "/health",
            "triage": "/api/v1/triage",
            "app_config": "/api/v1/app/config",
            "app_version": "/api/v1/app/version",
            "download_apk": "/api/v1/app/download-apk",
            "api_documentation": "/docs"
        },
        "version": "3.1.0"
    }

@app.get("/health")
@app.get("/healthz")
async def health_check():
    """Simple health check endpoint to verify the server is running."""
    return {"status": "healthy", "service": "Triage API"}

@app.get("/api/v1/app/version")
async def get_app_version():
    """Provides client version info and direct download URL for seamless in-app updating."""
    return {
        "latest_version": "3.1.0",
        "release_tag": "v3.1.0-master",
        "released_at": "2026-11-14T22:00:00Z",
        "apk_download_url": "/api/v1/app/download-apk",
        "web_live_url": "/app",
        "changelog": [
            "Interactive Closed-Loop Care Dossier Modal (ADPHC Miss Hura Hassan Mandate)",
            "One-Tap Safety-Net Stress-Test Cards (Inception 42 Benchmarking)",
            "Simulated Sahatna Citizen Push Nudge Alert",
            "Deterministic TDS Formula Derivation Inspector (Strict Zero-LLM Math)",
            "Malaffi HIE FHIR Bundle JSON Resource Inspector"
        ]
    }

@app.get("/api/v1/app/download-apk")
async def download_apk():
    """Directly streams the latest signed SkinGuard-Master APK."""
    apk_path = os.path.join(STATIC_DIR, "SkinGuard-Master-v3.apk")
    if os.path.exists(apk_path):
        return FileResponse(
            path=apk_path,
            filename="SkinGuard-Master-v3.apk",
            media_type="application/vnd.android.package-archive"
        )
    raise HTTPException(status_code=404, detail="APK build not found on server")

@app.get("/api/v1/app/config")
async def get_app_config():
    """Dynamic Server-Driven UI Configuration (Updates mobile app instantly without APK rebuilds)."""
    return {
        "platform_title": "SkinGuard UAE • Future Health 2026",
        "announcement_banner": {
            "enabled": True,
            "message": "Future Health 2026 Live: Connected to Cleveland Clinic Abu Dhabi (2WW) & Malaffi HIE",
            "type": "info"
        },
        "care_pathway": {
            "partner_hospital": "Cleveland Clinic Abu Dhabi (2WW)",
            "accountable_navigator": "Fatima Al-Mansouri, RN",
            "sla_target_days": 14,
            "stage_status": "Stage 3/5 Active"
        },
        "features": {
            "enable_live_camera": True,
            "enable_sahatna_simulator": True,
            "enable_malaffi_fhir_export": True,
            "deterministic_math_inspector": True
        }
    }

@app.on_event("startup")
async def startup_event():
    """Auto-indexes clinical guideline SOPs into Qdrant if collection is unindexed."""
    from app.services.ingest_guidelines import ingest_guidelines
    from app.services.qdrant_client import qdrant_db
    try:
        count = await asyncio.to_thread(ingest_guidelines, qdrant_db)
        print(f"✅ Indexed {count} clinical guideline chunks into Qdrant vector memory.")
    except Exception as e:
        print(f"Startup vector index notice: {e}")

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