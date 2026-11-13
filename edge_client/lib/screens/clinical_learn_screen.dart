import 'package:flutter/material.dart';

/// Page 3: Clinical Protocols, SOP Guidelines & Regulatory Standards.
/// Provides deep educational reference on population health triage,
/// Stolz ABCD dermoscopy, and FDA/MDR SaMD compliance.
class ClinicalLearnScreen extends StatelessWidget {
  const ClinicalLearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF8FAFC);
    const textDark = Color(0xFF0F172A);
    const textMuted = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CLINICAL GUIDELINES & PROTOCOLS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textDark,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              'Evidence-Based Standards & SaMD Compliance',
              style: TextStyle(
                fontSize: 11,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_outlined, color: Color(0xFF38BDF8), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'POPULATION HEALTH CHALLENGE 2026',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF38BDF8),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Closing the Screening-to-Care Loop',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'SkinGuard eliminates diagnostic dead-ends by connecting community edge screening to authorized clinical referral pathways with explicit turnaround timelines.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFCBD5E1),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 1: Clinical Standard Operating Procedures (SOPs)
          _buildSectionHeader('VERIFIED CLINICAL PROTOCOLS (SOP-001 TO SOP-005)'),
          const SizedBox(height: 10),

          _buildProtocolCard(
            sopCode: 'SOP-001',
            title: 'Suspected Cutaneous Malignancy (Rapid 2WW Pathway)',
            window: 'Target: 7 to 14 Days',
            color: const Color(0xFFDC2626),
            description:
                'Triggered when edge probability indicates elevated melanoma risk (≥ 60%). Mandates immediate secondary care referral to a specialized oncology center for urgent diagnostic dermoscopy and excision biopsy under NHS Two-Week-Wait guidelines.',
          ),
          const SizedBox(height: 10),

          _buildProtocolCard(
            sopCode: 'SOP-002',
            title: 'Atypical Dysplastic Nevus (Teledermatology Triage)',
            window: 'Target: Within 21 Days',
            color: const Color(0xFFD97706),
            description:
                'Triggered on intermediate atypical presentation (20%–59%). Enrolls patient into asynchronous store-and-forward teledermatology review with digital dermoscopic follow-up and patient self-examination education.',
          ),
          const SizedBox(height: 10),

          _buildProtocolCard(
            sopCode: 'SOP-003',
            title: 'Benign Cutaneous Lesion (Annual Primary Care Review)',
            window: 'Target: Routine 90 Days',
            color: const Color(0xFF059669),
            description:
                'Triggered when benign probability exceeds 80%. Reassures patient, prevents unnecessary specialist clinic overburdening, and schedules routine primary care annual checks.',
          ),
          const SizedBox(height: 10),

          _buildProtocolCard(
            sopCode: 'SOP-004',
            title: 'Optical Domain Shift & Sensor Quality Escalation',
            window: 'Target: Within 7 Days',
            color: const Color(0xFF0284C7),
            description:
                'Activated when motion blur, severe underexposure, or specular glare degrades feature extraction. Classifies target as indeterminate and routes patient to community health center for in-person dermoscopy.',
          ),

          const SizedBox(height: 24),

          // Section 2: Stolz ABCD Dermoscopy Criteria
          _buildSectionHeader('EXPLAINABLE AI: STOLZ ABCD DERMOSCOPY CRITERIA'),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildAbcdItem(
                  letter: 'A',
                  title: 'Asymmetry Index (Weight: 1.3)',
                  desc: 'Divides lesion across orthogonal axes to quantify 4-quadrant melanin distribution divergence.',
                ),
                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                _buildAbcdItem(
                  letter: 'B',
                  title: 'Border Irregularity (Weight: 0.1)',
                  desc: 'Measures perimeter gradient sharpness and jagged structural abruptness.',
                ),
                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                _buildAbcdItem(
                  letter: 'C',
                  title: 'Color Variegation (Weight: 0.5)',
                  desc: 'Evaluates standard deviations across red, brown, black, white, and bluish-gray pigments.',
                ),
                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                _buildAbcdItem(
                  letter: 'D',
                  title: 'Diameter & Differential (Weight: 0.5)',
                  desc: 'Maps features into ISIC 7-class ontology with ICD-10 diagnostic codes.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 3: Regulatory Compliance (FDA SaMD & Zero-PII)
          _buildSectionHeader('REGULATORY SAFETY & ZERO-PII ARCHITECTURE'),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security_rounded, color: Color(0xFF0284C7), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'FDA SaMD Class IIa & EU MDR Rule 11',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  '1. Zero-PII Guarantee: Patient skin photographs NEVER leave the mobile handset. Only numerical mathematical tensors are processed.\n\n'
                  '2. Clinician Gatekeeper: Diagnostic referrals cannot be finalized without attending clinician counter-signature.\n\n'
                  '3. Resilient SaMD Circuit Breaker: If network disconnects, on-device deterministic SOP safety nets engage instantly to protect patient care.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFF0284C7),
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildProtocolCard({
    required String sopCode,
    required String title,
    required String window,
    required Color color,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  sopCode,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              Text(
                window,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbcdItem({
    required String letter,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF0284C7).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              letter,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0284C7),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
