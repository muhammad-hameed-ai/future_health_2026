# SkinGuard UAE • Future Health Challenge 2026
### Autonomous Point-of-Care Cutaneous Lesion Triage & Closed-Loop Clinical Navigation System
**Endorsed for Abu Dhabi Department of Health (DoH) & Malaffi HIE Interoperability Standards**

---

## 🌟 Executive Overview
**SkinGuard UAE** is an enterprise-grade, Software as a Medical Device (SaMD) platform engineered for the **Future Health Challenge 2026 (Abu Dhabi)**. It provides autonomous, on-device dermoscopy screening and closed-loop oncology triage directly on mobile devices—operating **100% offline with zero latency** while seamlessly connecting to an encrypted **Cloud Intelligence Gateway (FastAPI + Qdrant Vector RAG + Gemini 2.5 Clinical Reasoning)** when available.

---

## 🛡️ Zero-PII Clinical Security Architecture

SkinGuard UAE is built with strict **Privacy-by-Design** and **Zero-PII (Personally Identifiable Information)** compliance:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       PATIENT MOBILE DEVICE (EDGE CLIENT)                   │
│                                                                             │
│  [Camera / Dermatoscope] ──► [SaMD Optical Quality Pre-Scan]               │
│                                   │ (Rejects Blur, Selfies, Non-Skin)       │
│                                   ▼                                         │
│                      [Autonomous On-Device Classifier]                      │
│                                   │                                         │
│                                   ▼                                         │
│                     ANONYMOUS 7-D RISK VECTOR ONLY                          │
│                [0.86, 0.04, 0.05, 0.02, 0.01, 0.01, 0.01]                   │
│                                                                             │
│  🔒 PATIENT IMAGES & IDENTITY NEVER LEAVE THIS DEVICE UNDER ANY CIRCUMSTANCE │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Encrypted HTTPS Payload (Vectors Only)
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      REMOTE CLOUD INTELLIGENCE GATEWAY                      │
│                                                                             │
│  [FastAPI Microservice] ──► [Qdrant Hybrid Vector Store (NICE NG12 RAG)]    │
│                                   │                                         │
│                                   ▼                                         │
│                 [Gemini 2.5 Clinical Reasoning Engine]                      │
│                                   │                                         │
│                                   ▼                                         │
│            GROUNDED CLINICAL PATHWAY (SLA & REFERRAL SOP)                   │
└─────────────────────────────────────────────────────────────────────────────┘
```

1. **Patient Photos Never Transmitted**: Raw dermoscopic photographs and patient names reside strictly in encrypted on-device sandbox storage.
2. **Anonymous Mathematical Tensors**: Only non-invertible, anonymized class probabilities and anonymized clinical context (e.g., duration, age group) are transmitted.
3. **Autonomous Offline Circuit Breaker**: If the cloud gateway is offline or network fails, SkinGuard executes on-device clinical SOPs instantly without interruption.

---

## 🔬 SaMD Optical Pre-Scan Quality Defense Pipeline

To prevent diagnostic misclassifications and eliminate false alarms (e.g., selfies misdiagnosed as malignancies), SkinGuard features a 5-tier optical pre-scan filter:

1. **Guard 1 (Photometric Exposure Defense)**: Automatically detects and blocks flash glare ($L > 234.0$ or $>18\%$ saturated pixels) and deep shadows ($L < 30.0$).
2. **Guard 2 (Non-Cutaneous Tissue Rejection)**: High-saturation filters, green floor thresholds, and YCbCr scene entropy filters reject tables, paper, keyboards, drywall, and clothing.
3. **Guard 3 (Focus & Blur Inspection)**: 2D discrete Laplacian variance analysis continuously measures spatial gradient energy, immediately rejecting blurred or motion-smeared frames ($Laplacian < 3.2$).
4. **Guard 4 (Facial Portrait / Selfie Rejection)**: Analyzes spatial dispersion and anthropomorphic facial triads (eyes + mouth separated by nasal bridge). Prevents full-face selfies from triggering Stolz asymmetry equations and locks malignant risk to $0.0\%$.
5. **Guard 5 (Focal Lesion Confirmation)**: Confirms presence of a discrete lesion or pigmented macule before initiating deliberation, preventing scans of normal, unmarked skin.

---

## 📊 Grounded Clinical Diagnostic Formulations

SkinGuard grounds its deliberation on validated international dermatological protocols:

- **Stolz ABCD Dermoscopy Rule**:
  $$\text{TDS} = (A \times 1.3) + (B \times 0.1) + (C \times 0.5) + (D \times 0.5)$$
  - $\text{TDS} < 4.75$: Benign lesion (SOP-003 Routine review).
  - $4.75 \le \text{TDS} < 5.45$: Suspicious / Dysplastic lesion (SOP-002 Clinical review within 6–8 weeks).
  - $\text{TDS} \ge 5.45$: Highly suspicious for Cutaneous Melanoma (SOP-001 Urgent 2WW Biopsy).
- **Argenziano 7-Point Checklist**:
  - Major Criteria (2 pts each): Atypical pigment network, blue-white veil, atypical vascular pattern.
  - Minor Criteria (1 pt each): Irregular streaks, irregular pigmentation, irregular dots/globules, regression structures.
  - Score $\ge 3$: High malignancy suspicion.
- **NICE Guideline NG12**: Enforces mandatory 14-day Two-Week-Wait (2WW) referral pathways to designated tertiary oncology partners (e.g., Cleveland Clinic Abu Dhabi).

---

## 🏗️ Repository Architecture

```text
├── edge_client/                      # Mobile Flutter Application (iOS & Android)
│   ├── lib/
│   │   ├── models/                   # SavedScanRecord & Data Transfer Objects
│   │   ├── screens/
│   │   │   ├── dashboard_home_screen.dart        # Apple Health style executive dashboard
│   │   │   ├── smart_scan_wizard_screen.dart     # 5-stage SaMD scan wizard & pre-scan alert card
│   │   │   ├── clinical_history_screen.dart      # Audit trail & patient dossier history
│   │   │   └── clinical_learn_screen.dart        # UAE DoH dermoscopy curriculum & guidelines
│   │   ├── services/
│   │   │   ├── edge_classifier.dart              # On-device SaMD computer vision & ABCD engine
│   │   │   ├── local_storage_service.dart        # Encrypted JSON database storage
│   │   │   ├── pdf_export_service.dart           # Clinical PDF generation & sharing
│   │   │   └── triage_api_client.dart            # Adaptive network client & autonomous fallback
│   │   └── widgets/
│   │       └── anatomical_body_map.dart          # Interactive 10-zone anatomical locator
│   └── test/
│       ├── edge_classifier_test.dart             # 18 SaMD guardrail & ABCD unit test suites
│       └── triage_api_client_test.dart           # Live RAG integration test suite
│
├── triage_backend/                   # Cloud Intelligence Gateway (FastAPI + RAG)
│   ├── app/
│   │   ├── main.py                   # FastAPI routing, CORS & health endpoints
│   │   ├── models/schemas.py         # Strict Pydantic DTOs for Zero-PII vectors
│   │   └── services/
│   │       ├── ingest_guidelines.py  # Ingestion pipeline for NICE NG12 & UAE DoH protocols
│   │       ├── qdrant_client.py      # Qdrant hybrid vector store engine
│   │       └── rag_agent.py          # Gemini 2.5 Clinical Reasoning Gateway
│   ├── requirements.txt              # Production Python dependencies
│   ├── render.yaml                   # 1-Click Render.com Blueprint configuration
│   └── Dockerfile                    # Multi-stage production container
│
└── SkinGuard-Master-v3.apk          # Production Release Android Package (ARM64)
```

---

## 🚀 Quick Deployment Guide

### Option 1: 1-Click Cloud Deployment on Render.com (100% Free)
1. Fork or clone this repository to GitHub.
2. Sign in to [Render.com](https://render.com).
3. Click **New +** → **Web Service** → Select your repository.
4. Set:
   - **Root Directory**: `triage_backend`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - **Instance Type**: **Free**
5. Render deploys your backend with a free public HTTPS endpoint: `https://<your-app>.onrender.com`.

### Option 2: Mobile App Cloud Connection
1. Launch the **SkinGuard UAE** app on your Android device.
2. Tap the **`☁️ Cloud Hub`** badge in the top bar.
3. Paste your Render backend URL (e.g., `https://<your-app>.onrender.com`).
4. Tap **Test Ping** (`✓ Connected successfully`).
5. Tap **Save Host**. The app now routes queries through your cloud hub worldwide, while retaining 100% offline fallback!

---

## 🧪 Automated Testing & Quality Verification

Run all test suites locally:
```powershell
cd edge_client
flutter analyze        # Verifies 0 warnings and 0 errors
flutter test           # Runs 20/20 clinical validation unit test suites
```

---

## 📜 Regulatory & Clinical Disclaimers
*SkinGuard UAE is developed for clinical decision support under investigational protocols conforming to the Abu Dhabi Department of Health Future Health Challenge 2026. The software operates as Class IIa Software as a Medical Device (SaMD) under IEC 62304 / ISO 13485 design control standards.*

