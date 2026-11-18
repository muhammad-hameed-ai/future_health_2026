import os
import time
import asyncio
from collections import defaultdict
from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse, FileResponse, RedirectResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.models.schemas import TriageRequest, TriageResponse
from app.services import rag_agent
from app.routers import auth

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB_DIST_DIR = os.path.join(BASE_DIR, "web_dist")
STATIC_DIR = os.path.join(BASE_DIR, "static")

app = FastAPI(
    title="Future Health Triage API & Live Web Portal",
    version="4.0.0",
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

# -----------------------------------------------------------------------------
# DEFENSIVE SECURITY & ADAPTIVE RATE LIMITING (Anti-Brute-Force & Anti-DoS)
# -----------------------------------------------------------------------------
_request_records = defaultdict(list)
MAX_AUTH_REQ_PER_MIN = 25
MAX_TRIAGE_REQ_PER_MIN = 60
MAX_PAYLOAD_BYTES = 15 * 1024 * 1024  # 15 MB payload guard

@app.middleware("http")
async def security_and_rate_limit_middleware(request: Request, call_next):
    # 1. Payload size guard against memory exhaustion
    content_length = request.headers.get("content-length")
    if content_length:
        try:
            if int(content_length) > MAX_PAYLOAD_BYTES:
                return JSONResponse(
                    status_code=413,
                    content={"detail": "Payload too large. Maximum allowed request size is 15MB."}
                )
        except ValueError:
            pass

    # 2. Adaptive rate limiting for sensitive paths
    path = request.url.path
    if path.startswith("/api/v1/auth") or path.startswith("/api/v1/triage"):
        client_ip = request.client.host if request.client else "unknown"
        forwarded = request.headers.get("x-forwarded-for")
        if forwarded:
            client_ip = forwarded.split(",")[0].strip()

        now = time.time()
        segment = path.split('/')[4] if len(path.split('/')) > 4 else path
        key = f"{client_ip}:{segment}"
        timestamps = _request_records[key]

        # Purge records older than 60 seconds
        _request_records[key] = [t for t in timestamps if now - t < 60.0]
        timestamps = _request_records[key]

        limit = MAX_AUTH_REQ_PER_MIN if "/auth" in path else MAX_TRIAGE_REQ_PER_MIN
        if len(timestamps) >= limit:
            return JSONResponse(
                status_code=429,
                headers={"Retry-After": "60"},
                content={"detail": "Rate limit exceeded. System security threshold reached, please wait 60 seconds."}
            )
        timestamps.append(now)

    # Execute request
    response = await call_next(request)

    # 3. Defensive OWASP Security Headers
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "SAMEORIGIN"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    return response

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Formats validation errors into clean, patient-friendly human readable messages."""
    errors = exc.errors()
    if errors:
        first_err = errors[0]
        field_loc = first_err.get("loc", [""])[-1]
        field_name = str(field_loc).replace("_", " ").capitalize()
        err_type = first_err.get("type", "")
        
        if "string_too_short" in err_type:
            min_len = first_err.get("ctx", {}).get("min_length", 6)
            clean_message = f"{field_name} must be at least {min_len} characters long."
        elif "string_too_long" in err_type:
            max_len = first_err.get("ctx", {}).get("max_length", 128)
            clean_message = f"{field_name} cannot exceed {max_len} characters."
        elif "missing" in err_type:
            clean_message = f"{field_name} is required."
        else:
            clean_message = first_err.get("msg", "Invalid input format.")
    else:
        clean_message = "Validation error. Please verify your input."
        
    return JSONResponse(
        status_code=422,
        content={"detail": clean_message}
    )

# Include Authentication & Profile Management Router
app.include_router(auth.router)

# Mount Flutter Web Live Application at /app
if os.path.exists(WEB_DIST_DIR):
    app.mount("/app", StaticFiles(directory=WEB_DIST_DIR, html=True), name="web_app")

# Mount static files (including direct APK downloads)
if os.path.exists(STATIC_DIR):
    app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")

@app.get("/welcome")
async def welcome_page():
    """Serves the official UAE Digital Health welcome gateway."""
    welcome_path = os.path.join(STATIC_DIR, "welcome.html")
    if os.path.exists(welcome_path):
        return FileResponse(welcome_path, media_type="text/html")
    return FileResponse(os.path.join(WEB_DIST_DIR, "index.html"))

@app.get("/")
async def root(request: Request):
    """Root landing endpoint providing clinical gateway operational status and endpoints."""
    # When accessed directly from a human web browser, seamlessly route to the Flutter Web App
    accept = request.headers.get("accept", "")
    if "text/html" in accept and os.path.exists(WEB_DIST_DIR):
        return RedirectResponse(url="/app/")

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
        "version": "4.0.0"
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
        "latest_version": "4.0.0",
        "release_tag": "v4.0.0-master-onnx",
        "released_at": "2026-11-15T13:15:00Z",
        "apk_download_url": "/api/v1/app/download-apk",
        "web_live_url": "/app",
        "changelog": [
            "Full On-Device 3-Stage Cascaded ONNX Pipeline (MobileNetV3 OOD Gate + Dual EfficientNet-B2 Heads)",
            "Forward 7x7 Class Activation Map (CAM) Heatmap Visualization",
            "Dual-Head Modality Selector (Dermatoscope Lens vs Direct Smartphone Camera)",
            "Two-Stage Probability Calibration Engine (ECE = 0.0072)",
            "Closed-Loop Hospital Triage (Cleveland Clinic Abu Dhabi 2WW + Malaffi HIE FHIR Bundles)"
        ]
    }

@app.get("/api/v1/app/download-apk")
async def download_apk():
    """Directly streams the latest signed SkinGuard-Master APK."""
    apk_path = os.path.join(STATIC_DIR, "SkinGuard-Master-v4.apk")
    if os.path.exists(apk_path):
        return FileResponse(
            path=apk_path,
            filename="SkinGuard-Master-v4.apk",
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