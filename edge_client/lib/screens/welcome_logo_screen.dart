import 'dart:math';
import 'package:flutter/material.dart';
import 'main_navigation_shell.dart';

/// Professional Welcome & Logo Gateway Screen.
/// Showcases the animated dermoscopy radar logo, the 2-step clinical architecture,
/// and regulatory zero-PII compliance before launching the Clinical Gateway.
class WelcomeLogoScreen extends StatefulWidget {
  const WelcomeLogoScreen({super.key});

  @override
  State<WelcomeLogoScreen> createState() => _WelcomeLogoScreenState();
}

class _WelcomeLogoScreenState extends State<WelcomeLogoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateToGateway(BuildContext context, {int initialTab = 0}) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MainNavigationShell(initialIndex: initialTab),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF8FAFC);
    const textDark = Color(0xFF0F172A);
    const textMuted = Color(0xFF64748B);
    const brandBlue = Color(0xFF0284C7);
    const brandEmerald = Color(0xFF059669);

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          children: [
            const SizedBox(height: 12),

            // 1. Top Challenge Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: brandBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: brandBlue.withOpacity(0.25)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.health_and_safety_rounded, color: brandBlue, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'FUTURE HEALTH 2026 • POPULATION ONCOLOGY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: brandBlue,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 2. Animated High-Precision Dermoscopy Radar Logo
            Center(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(150, 150),
                    painter: _RadarLogoPainter(angle: _animController.value * 2 * pi),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 3. App Title & Subtitle
            const Center(
              child: Column(
                children: [
                  Text(
                    'SkinGuard AI',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Clinical Oncology Gateway • Zero-PII Protocol',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: brandBlue,
                      letterSpacing: 0.4,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Closing the Screening-to-Care Loop',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 4. Section Title: How SkinGuard Works (2-Step Architecture)
            const Row(
              children: [
                Icon(Icons.account_tree_outlined, size: 16, color: brandBlue),
                SizedBox(width: 8),
                Text(
                  '2-STEP CLINICAL ARCHITECTURE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: brandBlue,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // STEP 01 CARD: On-Device Tissue Verification & ABCD Scan
            _buildStepCard(
              stepNumber: '01',
              title: 'On-Device Tissue Verification & ABCD Scan',
              tag: '100% On-Device • Edge AI',
              tagColor: brandBlue,
              icon: Icons.biotech_rounded,
              points: [
                '5-Tier Photobiological Guardrail verifies living human hemoglobin absorption and blocks keyboards, screens, woodgrain, and non-skin objects.',
                'Stolz ABCD feature extraction measures Asymmetry (A), Border Irregularity (B), Color Variegation (C), and Optical Focus (D).',
                'ISIC 7-Class International standard stratification (Melanoma, BCC, AKIEC, Nevus, Keratosis) with ICD-10 diagnostic mapping.',
                'Zero-PII Assurance: Raw patient photographs never leave the phone. Only an anonymous mathematical risk vector is generated.',
              ],
            ),

            const SizedBox(height: 14),

            // STEP 02 CARD: Grounded Clinical Triage & Care Loop Referral
            _buildStepCard(
              stepNumber: '02',
              title: 'Grounded Clinical Triage & Care Loop Referral',
              tag: 'FHIR Referral • Closed Care Loop',
              tagColor: brandEmerald,
              icon: Icons.hub_rounded,
              points: [
                'Vector RAG Engine: Embedded Qdrant database queries verified clinical standard operating procedures (SOP-001 through SOP-005).',
                'Google Gemini AI synthesizes structured, evidence-grounded triage pathways combining edge vectors with patient demographics & comorbidities.',
                'Actionable Turnaround: Explicit clinical windows (Urgent 2-Week-Wait vs. Routine 21-Day Teledermatology vs. 90-Day Observation).',
                'Official Clinical Dossier: Generates FHIR ServiceRequest (2WW) referral dossiers with clinician digital counter-signatures and PDF export.',
              ],
            ),

            const SizedBox(height: 28),

            // 5. Primary Launch Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandBlue,
                  elevation: 2,
                  shadowColor: brandBlue.withOpacity(0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _navigateToGateway(context, initialTab: 0),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.document_scanner_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'ENTER CLINICAL GATEWAY',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Secondary Navigation Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textDark,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.history_edu_rounded, size: 16, color: brandBlue),
                    label: const Text(
                      'Scan Registry',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _navigateToGateway(context, initialTab: 1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textDark,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.menu_book_rounded, size: 16, color: brandBlue),
                    label: const Text(
                      'Guidelines & SOPs',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _navigateToGateway(context, initialTab: 2),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 6. Regulatory & Privacy Guarantee Footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: brandEmerald, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FDA SaMD Class IIa • EU MDR Rule 11 Architecture',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Zero-PII Enforced: Local feature extraction ensures patient skin photos never leave this mobile device.',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: textMuted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String tag,
    required Color tagColor,
    required IconData icon,
    required List<String> points,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: tagColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(icon, color: tagColor, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'STEP $stepNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: tagColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: tagColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 10),

          // Bullet Points
          ...points.map((pt) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: tagColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      pt,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// Custom Painter for the High-Precision Animated Dermoscopy Radar Logo
class _RadarLogoPainter extends CustomPainter {
  final double angle;

  _RadarLogoPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Dark Clinical Base Disk
    final basePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF0369A1), Color(0xFF0F172A)],
        stops: [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius - 2, basePaint);

    // 2. Concentric Range Rings
    final ringPaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius * 0.35, ringPaint);
    canvas.drawCircle(center, radius * 0.65, ringPaint);
    canvas.drawCircle(center, radius * 0.90, ringPaint);

    // 3. Cardinal Crosshair Guides
    final guidePaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.35)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(center.dx, 10), Offset(center.dx, size.height - 10), guidePaint);
    canvas.drawLine(Offset(10, center.dy), Offset(size.width - 10, center.dy), guidePaint);

    // 4. Rotating Radar Sweep Beam
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: pi / 2,
        colors: [
          const Color(0xFF38BDF8).withOpacity(0.0),
          const Color(0xFF38BDF8).withOpacity(0.45),
        ],
        transform: GradientRotation(angle),
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.90));

    canvas.drawCircle(center, radius * 0.90, sweepPaint);

    // 5. Sweeping Ray Line
    final rayPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 1.8;
    final rayEnd = Offset(
      center.dx + radius * 0.90 * cos(angle + pi / 2),
      center.dy + radius * 0.90 * sin(angle + pi / 2),
    );
    canvas.drawLine(center, rayEnd, rayPaint);

    // 6. Central Cutaneous Focal Lesion Core
    final corePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF34D399), Color(0xFF059669)],
      ).createShader(Rect.fromCircle(center: center, radius: 14));
    canvas.drawCircle(center, 12, corePaint);

    // Inner White Reticle Dot
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 4, dotPaint);

    // Outer Decorative Corner Ticks
    final cornerTickPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const tick = 8.0;
    // Top
    canvas.drawLine(Offset(center.dx - tick, 4), Offset(center.dx + tick, 4), cornerTickPaint);
    // Bottom
    canvas.drawLine(Offset(center.dx - tick, size.height - 4), Offset(center.dx + tick, size.height - 4), cornerTickPaint);
    // Left
    canvas.drawLine(Offset(4, center.dy - tick), Offset(4, center.dy + tick), cornerTickPaint);
    // Right
    canvas.drawLine(Offset(size.width - 4, center.dy - tick), Offset(size.width - 4, center.dy + tick), cornerTickPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarLogoPainter oldDelegate) {
    return oldDelegate.angle != angle;
  }
}

