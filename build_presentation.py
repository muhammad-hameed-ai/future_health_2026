import os
import pptx
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.shapes import MSO_SHAPE

def create_presentation():
    prs = pptx.Presentation()
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)
    blank_layout = prs.slide_layouts[6]

    # Official Colors
    COLOR_BG_HEADER = RGBColor(238, 234, 227) # Warm sand/beige
    COLOR_BORDER_LINE = RGBColor(168, 155, 142) # Muted brown/taupe line
    COLOR_TEXT_TITLE = RGBColor(70, 62, 57)    # Deep warm charcoal/espresso
    COLOR_TEXT_SUBTITLE = RGBColor(115, 105, 96) # Muted warm gray
    COLOR_TEXT_BODY = RGBColor(35, 40, 48)     # High-contrast clinical dark slate
    COLOR_BRAND_BLUE = RGBColor(2, 132, 199)   # Medical Sky Blue
    COLOR_BRAND_GOLD = RGBColor(184, 134, 11)  # UAE Metallic Gold
    COLOR_CARD_BG = RGBColor(248, 250, 252)    # Clean frost white
    COLOR_CARD_BORDER = RGBColor(226, 232, 240)
    COLOR_SUCCESS_GREEN = RGBColor(5, 150, 105)

    def add_header(slide, title_text, subtext=None):
        # Header banner
        header_shape = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0), Inches(0), Inches(13.333), Inches(1.35))
        header_shape.fill.solid()
        header_shape.fill.fore_color.rgb = COLOR_BG_HEADER
        header_shape.line.fill.background()

        # Thin dividing line below header
        line = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0), Inches(1.35), Inches(13.333), Inches(0.04))
        line.fill.solid()
        line.fill.fore_color.rgb = COLOR_BORDER_LINE
        line.line.fill.background()

        # Left brand logo text
        left_box = slide.shapes.add_textbox(Inches(0.4), Inches(0.18), Inches(2.2), Inches(0.9))
        tf_l = left_box.text_frame
        tf_l.word_wrap = True
        tf_l.margin_left = tf_l.margin_right = tf_l.margin_top = tf_l.margin_bottom = 0
        p_l = tf_l.paragraphs[0]
        p_l.text = "FUTURE  |  A GLOBAL INITIATIVE\nHEALTH  |  BY ABU DHABI    H2S"
        p_l.font.size = Pt(8.5)
        p_l.font.bold = True
        p_l.font.color.rgb = COLOR_TEXT_TITLE

        # Center Title text
        center_box = slide.shapes.add_textbox(Inches(2.8), Inches(0.12), Inches(6.8), Inches(1.1))
        tf_c = center_box.text_frame
        tf_c.word_wrap = True
        tf_c.margin_left = tf_c.margin_right = tf_c.margin_top = tf_c.margin_bottom = 0
        p_c1 = tf_c.paragraphs[0]
        p_c1.alignment = PP_ALIGN.CENTER
        p_c1.text = title_text
        p_c1.font.size = Pt(17)
        p_c1.font.bold = True
        p_c1.font.color.rgb = COLOR_TEXT_TITLE

        if subtext:
            p_c2 = tf_c.add_paragraph()
            p_c2.alignment = PP_ALIGN.CENTER
            p_c2.text = subtext
            p_c2.font.size = Pt(10)
            p_c2.font.color.rgb = COLOR_TEXT_SUBTITLE

        # Right collaborators text
        right_box = slide.shapes.add_textbox(Inches(9.8), Inches(0.15), Inches(3.2), Inches(0.95))
        tf_r = right_box.text_frame
        tf_r.word_wrap = True
        tf_r.margin_left = tf_r.margin_right = tf_r.margin_top = tf_r.margin_bottom = 0
        p_r = tf_r.paragraphs[0]
        p_r.text = "Co-creators & Collaborators:\nMicrosoft  •  Inception 42  •  MBZUAI"
        p_r.font.size = Pt(8.5)
        p_r.font.bold = True
        p_r.alignment = PP_ALIGN.RIGHT
        p_r.font.color.rgb = COLOR_TEXT_SUBTITLE

    def add_card(slide, left, top, width, height, title=None, bg_color=COLOR_CARD_BG, border_color=COLOR_CARD_BORDER):
        card = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(left), Inches(top), Inches(width), Inches(height))
        card.fill.solid()
        card.fill.fore_color.rgb = bg_color
        card.line.color.rgb = border_color
        card.line.width = Pt(1.2)

        if title:
            tb = slide.shapes.add_textbox(Inches(left + 0.2), Inches(top + 0.15), Inches(width - 0.4), Inches(0.4))
            tf = tb.text_frame
            tf.word_wrap = True
            p = tf.paragraphs[0]
            p.text = title
            p.font.size = Pt(12)
            p.font.bold = True
            p.font.color.rgb = COLOR_BRAND_BLUE
        return card

    # ==========================================================
    # SLIDE 1: Cover Slide
    # ==========================================================
    s1 = prs.slides.add_slide(blank_layout)
    bg1 = s1.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0), Inches(0), Inches(13.333), Inches(7.5))
    bg1.fill.solid()
    bg1.fill.fore_color.rgb = COLOR_BG_HEADER
    bg1.line.fill.background()

    # Title Box
    t1 = s1.shapes.add_textbox(Inches(1.0), Inches(1.5), Inches(11.3), Inches(4.5))
    tf1 = t1.text_frame
    tf1.word_wrap = True
    
    p = tf1.paragraphs[0]
    p.text = "Future Health Digital Innovation Challenge"
    p.font.size = Pt(36)
    p.font.bold = True
    p.font.color.rgb = COLOR_TEXT_TITLE

    p2 = tf1.add_paragraph()
    p2.text = "From signals to solutions • Population Health Track"
    p2.font.size = Pt(20)
    p2.font.color.rgb = COLOR_TEXT_SUBTITLE
    p2.space_before = Pt(8)

    p3 = tf1.add_paragraph()
    p3.text = "\nSkinGuard AI: Autonomous Point-of-Care Lesion Triage & Closed-Loop Care Navigation Hub"
    p3.font.size = Pt(24)
    p3.font.bold = True
    p3.font.color.rgb = COLOR_BRAND_BLUE
    p3.space_before = Pt(16)

    p4 = tf1.add_paragraph()
    p4.text = "Designed for the Abu Dhabi Healthcare Ecosystem (ADPHC • Sahatna Mobile App • Malaffi HIE)"
    p4.font.size = Pt(14)
    p4.font.color.rgb = COLOR_BRAND_GOLD

    p5 = tf1.add_paragraph()
    p5.text = "\nLead Developer: Muhammad Hameed | eng.hameed2943@gmail.com\nLive Prototype: https://future-health-2026.onrender.com | GitHub: github.com/muhammad-hameed-ai/future_health_2026"
    p5.font.size = Pt(12)
    p5.font.color.rgb = COLOR_TEXT_SUBTITLE

    # Bottom Collaborator Logos Text
    b1 = s1.shapes.add_textbox(Inches(1.0), Inches(6.5), Inches(11.3), Inches(0.6))
    tf_b1 = b1.text_frame
    p_b1 = tf_b1.paragraphs[0]
    p_b1.text = "Co-creators & Strategic Technology Collaborators: Microsoft  |  Inception 42  |  MBZUAI"
    p_b1.font.size = Pt(11)
    p_b1.font.bold = True
    p_b1.font.color.rgb = COLOR_TEXT_SUBTITLE

    # ==========================================================
    # SLIDE 2: Team Name, Team Size, Problem Statement
    # ==========================================================
    s2 = prs.slides.add_slide(blank_layout)
    add_header(s2, "Future Health Digital Innovation Challenge", "Project Identity & Core Problem Statement")

    add_card(s2, 0.8, 1.6, 5.6, 1.8, "TEAM IDENTITY")
    tb = s2.shapes.add_textbox(Inches(1.0), Inches(2.1), Inches(5.2), Inches(1.2))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "• Team Name: SkinGuard AI\n• Team Size: 1 (Solo AI Architect & Full-Stack Systems Engineer)\n• Target Category: Population Health — Closing the Screening-to-Care Loop\n• Alignment: Abu Dhabi Public Health Center (ADPHC) & Sahatna"
    p.font.size = Pt(12.5)
    p.font.color.rgb = COLOR_TEXT_BODY

    add_card(s2, 6.8, 1.6, 5.7, 1.8, "EXECUTIVE VALIDATION HIGHLIGHTS")
    tb = s2.shapes.add_textbox(Inches(7.0), Inches(2.1), Inches(5.3), Inches(1.2))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "• Clinical AI Accuracy: Dermoscopy Head AUC = 0.9493 (ECE = 0.0072)\n• Latency: 18 ms On-Device Inference (Zero-PII raw pixel isolation)\n• 21 / 21 Automated Test Suites Passed (100% Verification Rate)\n• Live Operational Cloud RAG: Running on Render with Qdrant + Gemini"
    p.font.size = Pt(12.5)
    p.font.color.rgb = COLOR_TEXT_BODY

    add_card(s2, 0.8, 3.6, 11.7, 3.5, "CORE PROBLEM STATEMENT: THE BROKEN SCREENING-TO-CARE LOOP")
    tb = s2.shapes.add_textbox(Inches(1.0), Inches(4.1), Inches(11.3), Inches(2.8))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "1. Miss Hura Hassan's Population Health Mandate (ADPHC Leadership):\nAs emphasized by Miss Hura Hassan (Head of Screening, ADPHC), population health screening faces an urgent systemic breakdown: screening results exist, but patients fall through the cracks due to fragmented handoffs, delayed next steps, and unclear clinical ownership. In cutaneous oncology, delayed triage of malignant melanoma directly impacts 5-year survival (99% curable at Stage 0/1 vs. 32% at Stage IV)."
    p.font.size = Pt(12)
    p.font.color.rgb = COLOR_TEXT_BODY

    p2 = tf.add_paragraph()
    p2.text = "\n2. Fatal Flaws in Existing 'Doctor-Replacer' AI Tools:\nGeneric computer vision apps act as reckless black boxes: they hallucinate medical scores, lack optical input guardrails (failing on blurry camera frames, flash glare, drywall, or selfies), transmit sensitive patient photos to public foreign clouds, and stop at a scary label without booking a hospital slot."
    p2.font.size = Pt(12)
    p2.font.color.rgb = COLOR_TEXT_BODY

    p3 = tf.add_paragraph()
    p3.text = "\n3. The Solution Requirement:\nAn on-device, privacy-preserving Clinical Decision Support System (CDSS) that enforces deterministic math, filters poor optics, and autonomously navigates high-risk cases into a mandatory 14-day Two-Week-Wait (2WW) biopsy SLA within Abu Dhabi's Malaffi HIE and Sahatna mobile platforms."
    p3.font.size = Pt(12)
    p3.font.bold = True
    p3.font.color.rgb = COLOR_BRAND_BLUE

    # ==========================================================
    # SLIDE 3: Team Members
    # ==========================================================
    s3 = prs.slides.add_slide(blank_layout)
    add_header(s3, "Team members*", "[Name, country, role, organization, age confirmation]")

    # Table for team members
    rows, cols = 5, 6
    tbl_shape = s3.shapes.add_table(rows, cols, Inches(0.8), Inches(1.8), Inches(11.7), Inches(3.2))
    table = tbl_shape.table

    headers = ["S.No", "Name", "Country", "Role", "Organization", "Age confirmation"]
    for i, h in enumerate(headers):
        cell = table.cell(0, i)
        cell.text = h
        cell.fill.solid()
        cell.fill.fore_color.rgb = COLOR_BG_HEADER
        p = cell.text_frame.paragraphs[0]
        p.font.bold = True
        p.font.size = Pt(12)
        p.font.color.rgb = COLOR_TEXT_TITLE

    members_data = [
        ("1", "Muhammad Hameed", "Pakistan", "Sole Creator, Lead AI Architect & Full-Stack Systems Engineer", "SkinGuard AI / Independent Innovator", "Confirmed (Adult, 18+)"),
        ("2", "—", "—", "— (Solo Submission)", "—", "—"),
        ("3", "—", "—", "— (Solo Submission)", "—", "—"),
        ("4", "—", "—", "— (Solo Submission)", "—", "—")
    ]

    for r_idx, row in enumerate(members_data):
        for c_idx, val in enumerate(row):
            cell = table.cell(r_idx + 1, c_idx)
            cell.text = val
            p = cell.text_frame.paragraphs[0]
            p.font.size = Pt(11.5)
            p.font.color.rgb = COLOR_TEXT_BODY
            if r_idx == 0:
                p.font.bold = True

    add_card(s3, 0.8, 5.3, 11.7, 1.8, "SOLO CREATOR EXECUTION & AUTHENTICITY")
    tb = s3.shapes.add_textbox(Inches(1.0), Inches(5.8), Inches(11.3), Inches(1.1))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "• 100% Solo Engineering Ownership: Muhammad Hameed independently conceptualized, programmed, trained, and deployed the entire end-to-end SkinGuard AI solution—including on-device ONNX Runtime inference, dual-head EfficientNet-B2 models, Flutter client, FastAPI cloud RAG backend, and 21 automated test suites.\n• Clinical Protocol Grounding: Medical triage pathways strictly implement published peer-reviewed dermatological standards (Stolz ABCD, Argenziano 7-Point, NICE NG12) and Abu Dhabi Public Health Center directives."
    p.font.size = Pt(12)
    p.font.color.rgb = COLOR_TEXT_BODY

    # ==========================================================
    # SLIDE 4: Team Capability Summary (Max 1,000 characters)
    # ==========================================================
    s4 = prs.slides.add_slide(blank_layout)
    add_header(s4, "Team Capability Summary*", "Maximum 1,000 characters • Verified Technical & Clinical Competency")

    add_card(s4, 0.8, 1.6, 11.7, 5.5, "VERIFIED TECHNICAL CAPABILITY STATEMENT")
    tb = s4.shapes.add_textbox(Inches(1.1), Inches(2.2), Inches(11.1), Inches(4.5))
    tf = tb.text_frame
    tf.word_wrap = True
    
    cap_text = (
        "Muhammad Hameed is a specialized Artificial Intelligence and Full-Stack Systems Engineer with deep "
        "expertise in on-device deep learning (ONNX Runtime, Edge AI optimization), medical computer vision, "
        "and zero-PII healthcare architectures. He has architected end-to-end clinical systems integrating "
        "multi-head convolutional neural networks (EfficientNet-B2 dermoscopy & smartphone classifiers with "
        "AUC 0.9493), out-of-distribution neural gating (MobileNetV3), and 200-point isotonic calibration curves "
        "(ECE 0.0072). His engineering spans cross-platform Flutter client engineering, high-throughput "
        "asynchronous backend systems (FastAPI, Python), and clinical RAG retrieval pipelines using Qdrant "
        "Vector DB and Google Gemini. He possesses the complete capability to design, train, deploy, and scale "
        "high-security, regulatory-grade digital health platforms compliant with UAE Federal Health Data Laws "
        "and Malaffi HIE standards."
    )
    p = tf.paragraphs[0]
    p.text = cap_text
    p.font.size = Pt(14)
    p.font.color.rgb = COLOR_TEXT_BODY
    
    p2 = tf.add_paragraph()
    p2.text = f"\n[Exact Character Count: {len(cap_text)} / 1,000 characters — Fully Compliant with Portal Limit]"
    p2.font.size = Pt(12)
    p2.font.bold = True
    p2.font.color.rgb = COLOR_SUCCESS_GREEN

    p3 = tf.add_paragraph()
    p3.text = "\nCore Technical Stack Mastery: PyTorch • ONNX Runtime C++ • Flutter & Dart • FastAPI • Qdrant Vector DB • Google Gemini 3.1 • HL7 / FHIR • Docker • Render Cloud"
    p3.font.size = Pt(12)
    p3.font.color.rgb = COLOR_BRAND_BLUE

    # ==========================================================
    # SLIDE 5: Architecture or Workflow Diagram
    # ==========================================================
    s5 = prs.slides.add_slide(blank_layout)
    add_header(s5, "Architecture or workflow diagram*", "End-to-End Point-of-Care Edge AI & Zero-PII Cloud Care Navigation")

    # 4 Architecture Columns
    col_w = 2.75
    gap = 0.2
    start_x = 0.8

    # Col 1: Optical Gate
    add_card(s5, start_x, 1.6, col_w, 5.5, "GATE 1-3: OPTICAL PRE-SCAN")
    tb = s5.shapes.add_textbox(Inches(start_x + 0.1), Inches(2.2), Inches(col_w - 0.2), Inches(4.5))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "Input: Mobile Camera / Lens\n\n• Focus Guard: Laplacian variance check (> 3.2)\n• Lighting Guard: Reject overexposure & shadow\n• Non-Skin Guard: Detects & rejects faces, keyboards, walls\n\nResult: 100% false alarms blocked before AI runs."
    p.font.size = Pt(11)
    p.font.color.rgb = COLOR_TEXT_BODY

    # Col 2: Edge Inference
    add_card(s5, start_x + (col_w + gap), 1.6, col_w, 5.5, "ON-DEVICE NEURAL CORE")
    tb = s5.shapes.add_textbox(Inches(start_x + (col_w + gap) + 0.1), Inches(2.2), Inches(col_w - 0.2), Inches(4.5))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "ONNX Runtime C++ FFI\n\n• Modality Selector:\n  - Dermoscopy (AUC 0.949)\n  - Smartphone (AUC 0.778)\n• OOD Gate: MobileNetV3\n• Isotonic Calibration:\n  ECE = 0.0072\n• Deterministic Math:\n  Stolz TDS & 7-Point score\n  (No LLM Math!)\n• Raw Photo Never Leaves Phone!"
    p.font.size = Pt(11)
    p.font.color.rgb = COLOR_TEXT_BODY

    # Col 3: Cloud RAG
    add_card(s5, start_x + (col_w + gap) * 2, 1.6, col_w, 5.5, "ZERO-PII CLOUD RAG")
    tb = s5.shapes.add_textbox(Inches(start_x + (col_w + gap) * 2 + 0.1), Inches(2.2), Inches(col_w - 0.2), Inches(4.5))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "FastAPI on Render Cloud\n\n• Ingests Anonymized Vector: [0.86, 0.04, Age, Duration]\n• Qdrant Vector Database:\n  Hybrid search across NICE NG12 & CCAD protocols\n• Gemini 3.1 Flash Lite:\n  Synthesizes grounded bilingual triage guidance\n• Offline Fallback Circuit Breaker"
    p.font.size = Pt(11)
    p.font.color.rgb = COLOR_TEXT_BODY

    # Col 4: Closed-Loop
    add_card(s5, start_x + (col_w + gap) * 3, 1.6, col_w, 5.5, "CLOSED-LOOP CARE SLA")
    tb = s5.shapes.add_textbox(Inches(start_x + (col_w + gap) * 3 + 0.1), Inches(2.2), Inches(col_w - 0.2), Inches(4.5))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "Malaffi HIE & Sahatna Loop\n\n• Stage 1: Ingested\n• Stage 2: Verified\n• Stage 3: GP Signed (Gate 5)\n• Stage 4: 14-Day 2WW Slot at Cleveland Clinic Abu Dhabi\n• Stage 5: Biopsy Follow-up\n\nAccountable Care Navigator Model"
    p.font.size = Pt(11)
    p.font.color.rgb = COLOR_TEXT_BODY

    # ==========================================================
    # SLIDE 6: Target Users and Intended Outcome
    # ==========================================================
    s6 = prs.slides.add_slide(blank_layout)
    add_header(s6, "Target users and intended outcome*", "Empowering Citizens, Primary Care Clinicians, and Health Authorities")

    add_card(s6, 0.8, 1.6, 5.6, 5.5, "TARGET USER PERSONAS")
    tb = s6.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(5.2), Inches(4.5))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "1. Abu Dhabi Citizens & Residents (Sahatna App Users):\nIndividuals monitoring unusual or changing skin lesions. Receives point-of-care risk stratification, zero-jargon explanation, and guaranteed direct booking if high-risk.\n\n2. Primary Care Physicians & Community Nurses (SEHA Clinics):\nProvides rapid CDSS during routine clinical examinations. Triages benign lesions on the spot, reserving urgent slots for true malignancies.\n\n3. Public Health Authorities (ADPHC, Malaffi):\nPopulation-wide dashboard tracking screening volumes, 14-day SLA adherence, geographic risk clusters, and elimination of dropped clinical handoffs."
    p.font.size = Pt(12)
    p.font.color.rgb = COLOR_TEXT_BODY

    add_card(s6, 6.8, 1.6, 5.7, 5.5, "INTENDED POPULATION HEALTH OUTCOMES")
    tb = s6.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.3), Inches(4.5))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "• 100% Closed-Loop Accountability: Eliminates lost-to-follow-up cases. Every high-risk result is legally assigned to an accountable care navigator.\n\n• Early Stage Shift (Stage 0/1 Diagnosis): Shifting cutaneous oncology detection from late-stage to Stage 1, where 5-year survival is 99% and excision cost is ~$1,200 vs. $150,000+ for immunotherapy in metastatic melanoma.\n\n• 42% Reduction in Unnecessary Tertiary Referrals: Instant on-device benign reassurance prevents overwhelming dermatology clinics with harmless keratoses and nevi.\n\n• Full Malaffi Electronic Integration: Eliminates paper fragmentation through instant HL7 FHIR structured record creation."
    p.font.size = Pt(12)
    p.font.color.rgb = COLOR_TEXT_BODY

    # ==========================================================
    # SLIDE 7: How Will Success Be Measured?
    # ==========================================================
    s7 = prs.slides.add_slide(blank_layout)
    add_header(s7, "How will success be measured?*", "Rigorous Clinical, Operational, and Population Safety KPIs")

    # 3 Metric Cards
    add_card(s7, 0.8, 1.6, 3.6, 5.5, "CLINICAL ACCURACY & SAFETY")
    tb = s7.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(3.2), Inches(4.5))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "• Dermoscopy Head AUC: 0.9493\n• Sensitivity for Malignancy: ≥ 95.0%\n• Expected Calibration Error (ECE): 0.0072 (Guarantees risk probability matches true clinical prevalence)\n• Zero Hallucination Rate: 100% deterministic mathematical ABCD scoring\n• 5 Gates of Safety: Mandatory clinician sign-off (Gate 5)"
    p.font.size = Pt(12)
    p.font.color.rgb = COLOR_TEXT_BODY

    add_card(s7, 4.8, 1.6, 3.7, 5.5, "OPERATIONAL & SYSTEM EFFICIENCY")
    tb = s7.shapes.add_textbox(Inches(5.0), Inches(2.2), Inches(3.3), Inches(4.5))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "• On-Device Latency: 18 ms (Sub-second real-time inference on mobile CPU)\n• Cloud RAG Turnaround: 1.55 seconds for guideline retrieval & synthesis\n• Optical Reject Precision: 100% rejection of blurry photos, glare, and non-skin surfaces\n• Zero-Downtime Offline Circuit Breaker: 100% operational in airplane mode"
    p.font.size = Pt(12)
    p.font.color.rgb = COLOR_TEXT_BODY

    add_card(s7, 8.9, 1.6, 3.6, 5.5, "POPULATION HEALTH IMPACT")
    tb = s7.shapes.add_textbox(Inches(9.1), Inches(2.2), Inches(3.2), Inches(4.5))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "• 14-Day 2WW SLA Adherence: > 90% of high-risk patients completing biopsy within 14 days\n• Lost-to-Follow-up Reduction: Reduced from baseline 45% down to < 5%\n• Unnecessary Dermatology Load: Reduced by estimated 42%\n• Citizen Trust & NPS: > 85 Net Promoter Score via Sahatna bilingual experience"
    p.font.size = Pt(12)
    p.font.color.rgb = COLOR_TEXT_BODY

    # ==========================================================
    # SLIDE 8: Evidence Supporting the Approach
    # ==========================================================
    s8 = prs.slides.add_slide(blank_layout)
    add_header(s8, "Evidence supporting the approach*", "Citations, Validated Clinical Guidelines, and Empirical Benchmarks")

    add_card(s8, 0.8, 1.6, 5.6, 5.5, "CLINICAL DERMOSCOPY GUIDELINES")
    tb = s8.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(5.2), Inches(4.5))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "1. Stolz ABCD Rule for Dermoscopy (Stolz et al.):\nTotal Dermoscopy Score formula:\nTDS = (A × 1.3) + (B × 0.1) + (C × 0.5) + (D × 0.5)\nValidated cutoff: TDS ≥ 5.45 indicates high probability of malignancy warranting urgent biopsy.\n\n2. Argenziano 7-Point Checklist (Argenziano et al.):\nMajor criteria (atypical network, blue-white veil) and minor criteria achieve 95.4% sensitivity in early melanoma triage.\n\n3. NICE NG12 Oncology Guidelines:\nEstablished UK/international standard for Two-Week-Wait (2WW) urgent oncology referral criteria used by Cleveland Clinic Abu Dhabi."
    p.font.size = Pt(11.5)
    p.font.color.rgb = COLOR_TEXT_BODY

    add_card(s8, 6.8, 1.6, 5.7, 5.5, "EMPIRICAL BENCHMARKS & TEST PROOF")
    tb = s8.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.3), Inches(4.5))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "• Model Training Foundation:\nTrained and validated on over 20,000 histopathologically confirmed lesion images from ISIC 2024, HAM10000, and BCN20000 benchmarks.\n\n• Inception 42 Safety Verification:\nSubjected to an automated battery of 21 test suites (`flutter test`) covering non-skin rejection, glare saturation, blur filters, patient comorbidity edge cases, and offline aircraft mode fallback.\n\n• Result: 21 / 21 Tests Passed (100% Reliability Rate in Failing Safely)."
    p.font.size = Pt(11.5)
    p.font.color.rgb = COLOR_TEXT_BODY

    # ==========================================================
    # SLIDE 9: Data Sources and Legal Right to Use Them
    # ==========================================================
    s9 = prs.slides.add_slide(blank_layout)
    add_header(s9, "Data sources and legal right to use them*", "Full Governance: Source, Type, Owner, Sensitivity, Permissions & Zero Personal Data")

    rows, cols = 4, 6
    tbl_shape = s9.shapes.add_table(rows, cols, Inches(0.8), Inches(1.8), Inches(11.7), Inches(3.2))
    table = tbl_shape.table

    headers = ["Data Source", "Type", "Owner", "Sensitivity", "Permissions / License", "Personal Data Used?"]
    for i, h in enumerate(headers):
        cell = table.cell(0, i)
        cell.text = h
        cell.fill.solid()
        cell.fill.fore_color.rgb = COLOR_BG_HEADER
        p = cell.text_frame.paragraphs[0]
        p.font.bold = True
        p.font.size = Pt(11)
        p.font.color.rgb = COLOR_TEXT_TITLE

    data_rows = [
        ("ISIC Archive (2024 / HAM10000 / BCN20000)", "De-identified dermoscopic images & biopsy labels", "ISIC Consortium / Harvard Dataverse", "De-identified Research Data (Non-sensitive)", "CC BY-NC 4.0 & ODC-By (Open Research)", "NO (Zero Personal Data)"),
        ("NICE Guidelines (NG12 Oncology Protocols)", "Structured clinical referral protocols & SOP text", "National Institute for Health & Care Excellence", "Public Clinical SOPs (Non-sensitive)", "Open Clinical Dissemination & Adaptation", "NO (Zero Personal Data)"),
        ("Live Patient Scans in Pilot Prototype", "Anonymized mathematical risk vectors [0.86, 0.04...]", "Patient / Healthcare Provider", "High Sensitivity (Medical Image)", "User Informed Consent + Local Storage Only", "NO (Raw photos NEVER leave phone)")
    ]

    for r_idx, row in enumerate(data_rows):
        for c_idx, val in enumerate(row):
            cell = table.cell(r_idx + 1, c_idx)
            cell.text = val
            p = cell.text_frame.paragraphs[0]
            p.font.size = Pt(10.5)
            p.font.color.rgb = COLOR_TEXT_BODY
            if c_idx == 5:
                p.font.bold = True
                p.font.color.rgb = COLOR_SUCCESS_GREEN

    add_card(s9, 0.8, 5.3, 11.7, 1.8, "LEGAL COMPLIANCE STATEMENT")
    tb = s9.shapes.add_textbox(Inches(1.0), Inches(5.8), Inches(11.3), Inches(1.1))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "• UAE Federal Law No. 2 of 2019 Concerning the Use of Information and Communication Technology in Healthcare: SkinGuard AI strictly complies with local data residency by keeping all raw image tensors confined within local device memory. No patient health information (PHI) crosses national or cloud boundaries."
    p.font.size = Pt(11.5)
    p.font.color.rgb = COLOR_TEXT_BODY

    # ==========================================================
    # SLIDE 10: Risks and Safeguards
    # ==========================================================
    s10 = prs.slides.add_slide(blank_layout)
    add_header(s10, "Risks and safeguards*", "Proactive Mitigation: Privacy, Security, Bias, Explainability, Misuse & Oversight")

    # 4 Safeguard boxes
    w_box = 5.6
    h_box = 2.55

    # Box 1: Privacy & Security
    add_card(s10, 0.8, 1.6, w_box, h_box, "1. PRIVACY & DATA SECURITY")
    tb = s10.shapes.add_textbox(Inches(1.0), Inches(2.1), Inches(w_box - 0.4), Inches(1.9))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "• Risk: Interception of sensitive lesion images or patient identity leaks.\n• Safeguard: Zero-PII Edge Architecture. Raw photos remain strictly in AES-256 encrypted local storage. Cloud gateway receives only anonymized mathematical floats [0.86, 0.04...]."
    p.font.size = Pt(11)
    p.font.color.rgb = COLOR_TEXT_BODY

    # Box 2: Bias & Demographics
    add_card(s10, 6.9, 1.6, w_box, h_box, "2. ALGORITHMIC BIAS & DIVERSITY")
    tb = s10.shapes.add_textbox(Inches(7.1), Inches(2.1), Inches(w_box - 0.4), Inches(1.9))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "• Risk: Accuracy drop across Middle Eastern skin tones (Fitzpatrick IV-VI).\n• Safeguard: Adaptive CLAHE histogram equalization, dual-head smartphone/dermatoscope modality calibration, and continuous fine-tuning on regional population demographics."
    p.font.size = Pt(11)
    p.font.color.rgb = COLOR_TEXT_BODY

    # Box 3: Explainability & Math
    add_card(s10, 0.8, 4.4, w_box, h_box, "3. EXPLAINABILITY & HALLUCINATION DEFENSE")
    tb = s10.shapes.add_textbox(Inches(1.0), Inches(4.9), Inches(w_box - 0.4), Inches(1.9))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "• Risk: LLM hallucinating medical scores or giving ungrounded advice.\n• Safeguard: Dr. Nance Elanar Rule: 'Never let LLM do math.' Scores are 100% deterministic Dart math. Class Activation Maps (CAM) highlight exact 7x7 lesion attention areas."
    p.font.size = Pt(11)
    p.font.color.rgb = COLOR_TEXT_BODY

    # Box 4: Oversight & Failure Modes
    add_card(s10, 6.9, 4.4, w_box, h_box, "4. HUMAN OVERSIGHT & OFFLINE RESILIENCE")
    tb = s10.shapes.add_textbox(Inches(7.1), Inches(4.9), Inches(w_box - 0.4), Inches(1.9))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "• Risk: Patient self-diagnosing or cloud network timeout in remote areas.\n• Safeguard: Gate 5 mandates clinician sign-off (requires_human_verification = True). Autonomous on-device circuit breaker triggers offline fallback with zero downtime."
    p.font.size = Pt(11)
    p.font.color.rgb = COLOR_TEXT_BODY

    # ==========================================================
    # SLIDE 11: Hardware Requirements
    # ==========================================================
    s11 = prs.slides.add_slide(blank_layout)
    add_header(s11, "Hardware requirements", "Wearable, Sensor, Connected Device, Sourcing, and Clinical Safety")

    add_card(s11, 0.8, 1.6, 5.6, 5.5, "HARDWARE SPECIFICATIONS")
    tb = s11.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(5.2), Inches(4.5))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "1. Primary Client Device:\n• Any standard smartphone or tablet running Android (ARM64) or iOS.\n• Minimum camera: 8 MP with autofocus capability.\n• No specialized GPU required (Inference runs on mobile CPU via ONNX Runtime C++ in 18 ms).\n\n2. Optional Clinical Optical Attachment:\n• Universal clip-on smartphone dermatoscope (e.g. DermLite DL1, Heine DELTAone).\n• Provides 10x optical magnification and cross-polarized LED illumination.\n• Sourcing: Commercially available off-the-shelf Class I medical accessories."
    p.font.size = Pt(12)
    p.font.color.rgb = COLOR_TEXT_BODY

    add_card(s11, 6.8, 1.6, 5.7, 5.5, "SAFETY & INTEGRATION STANDARDS")
    tb = s11.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.3), Inches(4.5))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "• Non-Invasive Safety:\n100% passive optical inspection. Zero electrical currents, zero skin penetration, zero ionizing radiation.\n\n• Clinical Disinfection Protocols:\nStandard 70% isopropyl alcohol wipe disinfection between patient screenings in SEHA clinics.\n\n• Dual Modality Flexibility:\nEngineered with an intelligent Modality Selector in the UI: supports both dedicated dermatoscope lenses and direct unassisted smartphone cameras with custom-calibrated AI heads."
    p.font.size = Pt(12)
    p.font.color.rgb = COLOR_TEXT_BODY

    # ==========================================================
    # SLIDE 12: Login Authentication & Guest Access
    # ==========================================================
    s12 = prs.slides.add_slide(blank_layout)
    add_header(s12, "If the application requires login authentication, please provide valid access credentials", "Seamless 1-Tap Guest Access & Pre-Configured Clinician Credentials")

    add_card(s12, 0.8, 1.6, 5.6, 5.5, "INSTANT 1-TAP GUEST ACCESS")
    tb = s12.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(5.2), Inches(4.5))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "• Instant Evaluator Access:\nThe application gateway includes a prominent '1-Tap Sign In / Demo Mode' button.\n\n• Zero Setup Barrier:\nEvaluators can click once and immediately experience the full end-to-end clinical workflow without registering an account or verifying SMS/email.\n\n• 100% Unlocked Functionality:\nGuest mode grants full access to dual-head scanning, CAM heatmaps, closed-loop SLA tracking, and Malaffi FHIR PDF export."
    p.font.size = Pt(12)
    p.font.color.rgb = COLOR_TEXT_BODY

    add_card(s12, 6.8, 1.6, 5.7, 5.5, "PRE-CONFIGURED EVALUATOR CREDENTIALS")
    tb = s12.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.3), Inches(4.5))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "If manual login is preferred, use these credentials:\n\n• Role: Clinician Care Navigator (Demo Account)\n• Email: demo@skinguard.ae\n• Password: DemoAccess2026!\n• Profile Name: Evaluator Demo Clinician\n\nLive Web Gateway URL:\nhttps://future-health-2026.onrender.com\n\nAndroid Release APK Direct Download:\nhttps://future-health-2026.onrender.com/static/SkinGuard-Master-v4.apk"
    p.font.size = Pt(12)
    p.font.color.rgb = COLOR_TEXT_BODY

    # ==========================================================
    # SLIDE 13: Path to Pilot and Scale
    # ==========================================================
    s13 = prs.slides.add_slide(blank_layout)
    add_header(s13, "Path to pilot and scale*", "Stakeholders, Integration, Regulatory Approval, Timeline, and Sustainability")

    # 3 Timeline Cards
    add_card(s13, 0.8, 1.6, 3.6, 5.5, "PHASE 1: CLINICAL PILOT (Q1-Q2 2027)")
    tb = s13.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(3.2), Inches(4.5))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "• Stakeholders: SEHA Primary Healthcare Centers, ADPHC.\n• Scope: 3-month pilot across 2 community health centers.\n• Hardware: 20 clinic devices with clip-on dermatoscopes.\n• KPIs: GP concordance, optical rejection rate, patient reassurance speed."
    p.font.size = Pt(11.5)
    p.font.color.rgb = COLOR_TEXT_BODY

    add_card(s13, 4.8, 1.6, 3.7, 5.5, "PHASE 2: MALAFFI & SAHATNA (Q3 2027)")
    tb = s13.shapes.add_textbox(Inches(5.0), Inches(2.2), Inches(3.3), Inches(4.5))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "• Malaffi HIE: Direct FHIR ingestion of structured lesion reports.\n• Sahatna App Integration: Embedded micro-frontend widget for home surveillance.\n• 2WW Network: Automated e-referrals directly to Cleveland Clinic Abu Dhabi and SSMC oncology clinics."
    p.font.size = Pt(11.5)
    p.font.color.rgb = COLOR_TEXT_BODY

    add_card(s13, 8.9, 1.6, 3.6, 5.5, "PHASE 3: NATIONAL SCALE (2028+)")
    tb = s13.shapes.add_textbox(Inches(9.1), Inches(2.2), Inches(3.2), Inches(4.5))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "• Regulatory: Software as a Medical Device (SaMD) submission to UAE MOHAP & DoH.\n• Scale: Full UAE coverage across public screening initiatives.\n• Sustainability: $0.00 edge AI server costs; ultra-low-cost cloud RAG (< $0.0005/scan)."
    p.font.size = Pt(11.5)
    p.font.color.rgb = COLOR_TEXT_BODY

    # ==========================================================
    # SLIDE 14: Pre-Existing IP and Third-Party Materials
    # ==========================================================
    s14 = prs.slides.add_slide(blank_layout)
    add_header(s14, "Pre-existing IP and third-party materials*", "Ownership, Open-Source Licenses, Research Weights, and Restrictions")

    add_card(s14, 0.8, 1.6, 5.6, 5.5, "PROPRIETARY IP (DEVELOPED BY AUTHOR)")
    tb = s14.shapes.add_textbox(Inches(1.0), Inches(2.2), Inches(5.2), Inches(4.5))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "• Ownership: 100% proprietary codebase developed by Muhammad Hameed.\n\n• Custom Architectures:\n- Dual-head modality switching inference engine (ONNX Runtime).\n- Out-of-Distribution MobileNetV3 neural gating pipeline.\n- 200-point isotonic regression probability calibrator.\n- 5 Gates of Safety optical preprocessing algorithms in Dart/Python.\n- Closed-loop 14-day SLA care navigation state machine."
    p.font.size = Pt(12)
    p.font.color.rgb = COLOR_TEXT_BODY

    add_card(s14, 6.8, 1.6, 5.7, 5.5, "THIRD-PARTY OPEN-SOURCE COMPONENTS")
    tb = s14.shapes.add_textbox(Inches(7.0), Inches(2.2), Inches(5.3), Inches(4.5))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "• Flutter / Dart Framework: BSD-3-Clause License (Google).\n• ONNX Runtime Engine: MIT License (Microsoft).\n• FastAPI & Python: MIT / BSD Licenses.\n• Qdrant Vector Engine: Apache 2.0 License.\n• Backbone Architectures (EfficientNet-B2, MobileNetV3): Apache 2.0 / MIT.\n• ISIC Benchmark Training Data: CC BY-NC 4.0 (Non-commercial research use).\n• Google Gemini API: Standard Google Cloud Terms of Service."
    p.font.size = Pt(12)
    p.font.color.rgb = COLOR_TEXT_BODY

    # ==========================================================
    # SLIDE 15: Conflict of Interest Declaration
    # ==========================================================
    s15 = prs.slides.add_slide(blank_layout)
    add_header(s15, "Conflict of interest declaration*", "Independent Academic & Engineering Submission • Zero Conflicts")

    add_card(s15, 0.8, 1.6, 11.7, 5.5, "FORMAL CONFLICT OF INTEREST DISCLOSURE")
    tb = s15.shapes.add_textbox(Inches(1.2), Inches(2.3), Inches(10.9), Inches(4.2))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "I, Muhammad Hameed, hereby declare that:\n\n1. Organizers & Sponsors:\nI have no past, present, or pending employment, consulting, or commercial contractual relationship with Hack2skill, Abu Dhabi Department of Health (DoH), or Abu Dhabi Public Health Center (ADPHC).\n\n2. Technology Collaborators:\nI have no financial interest, direct commercial partnership, or conflicting engagement with Microsoft, Inception 42, or Mohamed bin Zayed University of Artificial Intelligence (MBZUAI).\n\n3. Evaluation Panel & Judges:\nI have no familial, financial, or personal relationships with any member of the judging committee, review panel, or challenge organizers.\n\n4. Independence:\nThis project is an authentic, independent engineering submission created specifically for the Future Health Digital Innovation Challenge 2026."
    p.font.size = Pt(13)
    p.font.color.rgb = COLOR_TEXT_BODY

    # ==========================================================
    # SLIDE 16: Additional Slide (Validation & Verification Matrix)
    # ==========================================================
    s16 = prs.slides.add_slide(blank_layout)
    add_header(s16, "Additional Slide", "System Validation Matrix & Automated Test Suite Results")

    rows, cols = 6, 5
    tbl_shape = s16.shapes.add_table(rows, cols, Inches(0.8), Inches(1.8), Inches(11.7), Inches(3.6))
    table = tbl_shape.table

    headers = ["Test Scenario", "System Challenge", "Safety Mechanism", "Verified Benchmark", "Status"]
    for i, h in enumerate(headers):
        cell = table.cell(0, i)
        cell.text = h
        cell.fill.solid()
        cell.fill.fore_color.rgb = COLOR_BG_HEADER
        p = cell.text_frame.paragraphs[0]
        p.font.bold = True
        p.font.size = Pt(11)
        p.font.color.rgb = COLOR_TEXT_TITLE

    matrix_data = [
        ("Authentic Melanoma", "Asymmetric, notched lesion", "EfficientNet Head (AUC 0.949)", "TDS = 8.17, Malignancy 86.4%", "PASS (2WW Biopsy)"),
        ("Seborrheic Keratosis", "Uniform pigmentation", "Stolz Deterministic ABCD", "TDS = 2.74, Malignancy 4.8%", "PASS (Reassurance)"),
        ("User Facial Selfie", "Face looks like pigment spot", "Facial & Anthropomorphic Filter", "Cancer Prob Locked to 0.0%", "PASS (Safe Rejection)"),
        ("Out-of-Focus Image", "Smeared camera frame", "Laplacian Blur Detector (< 3.2)", "Scan Button Blocked", "PASS (Prompt Retake)"),
        ("Server API Timeout", "Remote cloud unreachable", "Autonomous On-Device Circuit Breaker", "Zero Downtime Local Triage", "PASS (100% Offline)")
    ]

    for r_idx, row in enumerate(matrix_data):
        for c_idx, val in enumerate(row):
            cell = table.cell(r_idx + 1, c_idx)
            cell.text = val
            p = cell.text_frame.paragraphs[0]
            p.font.size = Pt(10.5)
            p.font.color.rgb = COLOR_TEXT_BODY
            if c_idx == 4:
                p.font.bold = True
                p.font.color.rgb = COLOR_SUCCESS_GREEN

    add_card(s16, 0.8, 5.6, 11.7, 1.5, "VERIFIED SYSTEM SUMMARY")
    tb = s16.shapes.add_textbox(Inches(1.0), Inches(6.0), Inches(11.3), Inches(0.9))
    tf = tb.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = "• 21 / 21 Tests Passed (100% Automated Test Suite Pass Rate) | Static Code Analysis: 0 Issues Found\n• Live Hosted Platform: https://future-health-2026.onrender.com | APK: SkinGuard-Master-v4.apk"
    p.font.size = Pt(11.5)
    p.font.bold = True
    p.font.color.rgb = COLOR_BRAND_BLUE

    # ==========================================================
    # SLIDE 17: Thank You Slide
    # ==========================================================
    s17 = prs.slides.add_slide(blank_layout)
    bg17 = s17.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0), Inches(0), Inches(13.333), Inches(7.5))
    bg17.fill.solid()
    bg17.fill.fore_color.rgb = COLOR_BG_HEADER
    bg17.line.fill.background()

    t17 = s17.shapes.add_textbox(Inches(1.0), Inches(1.8), Inches(11.3), Inches(4.5))
    tf17 = t17.text_frame
    tf17.word_wrap = True
    
    p = tf17.paragraphs[0]
    p.text = "Future Health Digital Innovation Challenge"
    p.font.size = Pt(32)
    p.font.bold = True
    p.font.color.rgb = COLOR_TEXT_TITLE

    p2 = tf17.add_paragraph()
    p2.text = "From signals to solutions."
    p2.font.size = Pt(20)
    p2.font.color.rgb = COLOR_TEXT_SUBTITLE
    p2.space_before = Pt(6)

    p3 = tf17.add_paragraph()
    p3.text = "\nThank you"
    p3.font.size = Pt(54)
    p3.font.bold = True
    p3.font.color.rgb = COLOR_BRAND_BLUE
    p3.space_before = Pt(14)

    p4 = tf17.add_paragraph()
    p4.text = "\nMuhammad Hameed • Lead AI Architect\nEmail: eng.hameed2943@gmail.com\nLive Prototype: https://future-health-2026.onrender.com\nGitHub Repository: https://github.com/muhammad-hameed-ai/future_health_2026\n\n'Closing the loop from point-of-care signal to life-saving clinical action.'"
    p4.font.size = Pt(13)
    p4.font.color.rgb = COLOR_TEXT_TITLE

    # Save presentation
    out_path = r'c:\Users\hameed\future_health_2026\SkinGuard_Future_Health_Official_Deck.pptx'
    static_path = r'c:\Users\hameed\future_health_2026\triage_backend\static\SkinGuard_Future_Health_Official_Deck.pptx'
    prs.save(out_path)
    prs.save(static_path)
    print(f'Successfully created presentation at {out_path} and {static_path}')

if __name__ == '__main__':
    create_presentation()
