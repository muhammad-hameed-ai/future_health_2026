import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'main_navigation_shell.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../services/inference_service.dart';
import '../services/language_service.dart';

/// Ultra-Premium UAE Digital Health Welcome Screen for SkinGuard AI.
/// 
/// Strictly matches the official design reference:
/// - Minimalist, clinical, trustworthy, production-ready.
/// - Pure white background (#FFFFFF) with subtle pale-mint illumination.
/// - Top header with compact SkinGuard brand lockup and English/Arabic toggle.
/// - UAE Digital Health indicator with waving UAE flag.
/// - Primary dual-tone headline ("Smarter skin triage. / Safer next steps.").
/// - Central clinical identity seal with rotating diagnostic rings, red '01' node,
///   pulsing gold focus point, 4 dermal curves, and floating UAE flag.
/// - Full-width "Enter SkinGuard" button with directional arrow and smooth navigation.
/// - Three trust indicators (Private, Clinical, Connected) and bottom status bar.
class WelcomeLogoScreen extends StatefulWidget {
  const WelcomeLogoScreen({super.key});

  @override
  State<WelcomeLogoScreen> createState() => _WelcomeLogoScreenState();
}

class _WelcomeLogoScreenState extends State<WelcomeLogoScreen>
    with TickerProviderStateMixin {
  // Locale State
  bool _isArabic = false;
  bool _navigated = false;

  // Animation Controllers
  late AnimationController _entranceController;
  late AnimationController _ringRotationController;
  late AnimationController _flagWaveController;
  late AnimationController _scanBeamController;
  late AnimationController _focusPulseController;

  // Staggered Entrance Animations
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _headlineFade;
  late Animation<Offset> _headlineSlide;
  late Animation<double> _subheadFade;
  late Animation<double> _sealFade;
  late Animation<double> _sealScale;
  late Animation<double> _buttonFade;
  late Animation<Offset> _buttonSlide;
  late Animation<double> _footerFade;

  @override
  void initState() {
    super.initState();

    _isArabic = LanguageService.isArabic;
    LanguageService.isArabicNotifier.addListener(_onLanguageChanged);

    // 1. Entrance Staggered Animation (1.2s total duration)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(_headerFade);

    _headlineFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.60, curve: Curves.easeOutCubic),
    );
    _headlineSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(_headlineFade);

    _subheadFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.30, 0.70, curve: Curves.easeOut),
    );

    _sealFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
    );
    _sealScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _buttonFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.60, 0.95, curve: Curves.easeOutCubic),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(_buttonFade);

    _footerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
    );

    // 2. Continuous Ring Rotation (24 seconds loop)
    _ringRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    // 3. Continuous Flag Waving Physics (3.2 seconds loop)
    _flagWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    // 4. Scanning Laser Beam Sweep (3.8 seconds loop)
    _scanBeamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat();

    // 5. Gold Focus Dot Pulsing (2.4 seconds loop)
    _focusPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Start Entrance
    _entranceController.forward();

    // Pre-warm ONNX engines in background
    _preWarmEngines();
  }

  void _preWarmEngines() async {
    try {
      if (!InferenceService.instance.isInitialized) {
        await InferenceService.instance.initialize();
      }
      await InferenceService.instance.warmUp();
    } catch (e) {
      debugPrint('Welcome warm-up notice: $e');
    }
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {
        _isArabic = LanguageService.isArabic;
      });
    }
  }

  @override
  void dispose() {
    LanguageService.isArabicNotifier.removeListener(_onLanguageChanged);
    _entranceController.dispose();
    _ringRotationController.dispose();
    _flagWaveController.dispose();
    _scanBeamController.dispose();
    _focusPulseController.dispose();
    super.dispose();
  }

  void _navigateToGateway() {
    if (!mounted || _navigated) return;
    _navigated = true;

    final Widget targetScreen = !AuthService.isAuthenticated
        ? LoginScreen(
            isArabic: LanguageService.isArabic,
            onLoginSuccess: () {
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const MainNavigationShell(initialIndex: 0),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
          )
        : const MainNavigationShell(initialIndex: 0);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  void _toggleLanguage() {
    LanguageService.toggleLanguage();
  }

  @override
  Widget build(BuildContext context) {
    // Palette Constants
    const Color bgWhite = Color(0xFFFFFFFF);
    const Color darkGreen = Color(0xFF092F34);
    const Color brandTeal = Color(0xFF08766F);
    const Color buttonTeal = Color(0xFF075A5A);
    const Color mutedGrey = Color(0xFF52796F);
    const Color borderMint = Color(0xFFD1E7DD);

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgWhite,
        body: SafeArea(
          bottom: true,
          top: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxHeight = constraints.maxHeight;
              final bool isCompact = maxHeight < 680;

              return Column(
                children: [
                  // ==========================================
                  // A. TOP HEADER
                  // ==========================================
                  FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: const BoxDecoration(
                          color: bgWhite,
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFF1F5F9),
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left Brand Lockup
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Mini Shield Icon
                                SizedBox(
                                  width: 24,
                                  height: 28,
                                  child: CustomPaint(
                                    painter: MiniShieldPainter(
                                      color: brandTeal,
                                      accentColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isArabic ? "سكين جارد" : "SKINGUARD",
                                      style: const TextStyle(
                                        color: darkGreen,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        height: 1.1,
                                      ),
                                    ),
                                    Text(
                                      _isArabic
                                          ? "الذكاء الاصطناعي السريري"
                                          : "CLINICAL AI",
                                      style: TextStyle(
                                        color: mutedGrey.withOpacity(0.9),
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Right Language Toggle
                            InkWell(
                              onTap: _toggleLanguage,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: borderMint,
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.language,
                                      size: 15,
                                      color: brandTeal.withOpacity(0.85),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _isArabic ? "English" : "العربية",
                                      style: const TextStyle(
                                        color: brandTeal,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ==========================================
                  // B. MAIN CONTENT BODY
                  // ==========================================
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Container(
                        constraints: BoxConstraints(
                          minHeight: math.max(0, maxHeight - 60),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const SizedBox(height: 8),

                            // 1. UAE DIGITAL HEALTH IDENTIFIER
                            FadeTransition(
                              opacity: _headlineFade,
                              child: SlideTransition(
                                position: _headlineSlide,
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Animated Waving UAE Flag (Mini)
                                        SizedBox(
                                          width: 22,
                                          height: 13,
                                          child: AnimatedBuilder(
                                            animation: _flagWaveController,
                                            builder: (context, _) {
                                              return CustomPaint(
                                                painter: UaeFlagMiniPainter(
                                                  phase: _flagWaveController.value *
                                                      2 *
                                                      math.pi,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isArabic
                                              ? "الصحة الرقمية الإماراتية"
                                              : "UAE DIGITAL HEALTH",
                                          style: const TextStyle(
                                            color: mutedGrey,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 2.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // 2. PRIMARY HEADLINE
                                    Text(
                                      _isArabic
                                          ? "فرز جلدي أكثر ذكاءً."
                                          : "Smarter skin triage.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: darkGreen,
                                        fontSize: isCompact ? 24 : 28,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.6,
                                        height: 1.15,
                                      ),
                                    ),
                                    Text(
                                      _isArabic
                                          ? "خطوات تالية أكثر أماناً."
                                          : "Safer next steps.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: brandTeal,
                                        fontSize: isCompact ? 24 : 28,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.6,
                                        height: 1.15,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // 3. SUPPORTING COPY
                                    FadeTransition(
                                      opacity: _subheadFade,
                                      child: Text(
                                        _isArabic
                                            ? "إرشاد سريري واضح للوصول إلى الرعاية في الوقت المناسب."
                                            : "Clinical guidance designed for clear, timely care.",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: mutedGrey,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // 4. CENTRAL CLINICAL IDENTITY SEAL
                            FadeTransition(
                              opacity: _sealFade,
                              child: ScaleTransition(
                                scale: _sealScale,
                                child: SizedBox(
                                  width: isCompact ? 230 : 260,
                                  height: isCompact ? 230 : 260,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Concentric Rings & Diagnostic Field Painter
                                      AnimatedBuilder(
                                        animation: Listenable.merge([
                                          _ringRotationController,
                                          _scanBeamController,
                                          _focusPulseController,
                                        ]),
                                        builder: (context, _) {
                                          return CustomPaint(
                                            size: Size(
                                              isCompact ? 230 : 260,
                                              isCompact ? 230 : 260,
                                            ),
                                            painter: ClinicalSealFieldPainter(
                                              rotationAngle:
                                                  _ringRotationController.value *
                                                      2 *
                                                      math.pi,
                                              scanProgress:
                                                  _scanBeamController.value,
                                              pulseScale:
                                                  _focusPulseController.value,
                                            ),
                                          );
                                        },
                                      ),

                                      // Central Shield with 4 Dermal Lines
                                      SizedBox(
                                        width: isCompact ? 60 : 70,
                                        height: isCompact ? 72 : 82,
                                        child: CustomPaint(
                                          painter: ClinicalDermalShieldPainter(
                                            color: brandTeal,
                                            accentColor: Colors.white,
                                          ),
                                        ),
                                      ),

                                      // Floating UAE Flag on Upper-Right Edge (~1-2 o'clock)
                                      Positioned(
                                        top: isCompact ? 22 : 26,
                                        right: isCompact ? 28 : 34,
                                        child: SizedBox(
                                          width: 38,
                                          height: 24,
                                          child: AnimatedBuilder(
                                            animation: _flagWaveController,
                                            builder: (context, _) {
                                              return CustomPaint(
                                                painter: UaeWavingClothFlagPainter(
                                                  phase: _flagWaveController.value *
                                                      2 *
                                                      math.pi,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),

                                      // Typography Lockup Below Shield
                                      Positioned(
                                        bottom: isCompact ? 26 : 30,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                const Text(
                                                  "SKINGUARD",
                                                  style: TextStyle(
                                                    color: darkGreen,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 1.4,
                                                    height: 1.0,
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 5, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF0F172A),
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    "AI",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.w900,
                                                      letterSpacing: 0.5,
                                                      height: 1.0,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _isArabic
                                                  ? "ذكاء سريري · رعاية إنسانية"
                                                  : "CLINICAL INTELLIGENCE · HUMAN CARE",
                                              style: TextStyle(
                                                color: mutedGrey.withOpacity(0.85),
                                                fontSize: 7.5,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.3,
                                                height: 1.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // 5. PRIMARY ACTION BUTTON
                            FadeTransition(
                              opacity: _buttonFade,
                              child: SlideTransition(
                                position: _buttonSlide,
                                child: Column(
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _navigateToGateway,
                                        borderRadius: BorderRadius.circular(14),
                                        child: Ink(
                                          width: double.infinity,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            color: buttonTeal,
                                            borderRadius: BorderRadius.circular(14),
                                            boxShadow: [
                                              BoxShadow(
                                                color: buttonTeal.withOpacity(0.28),
                                                blurRadius: 18,
                                                offset: const Offset(0, 7),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  _isArabic
                                                      ? "الدخول إلى سكين جارد"
                                                      : "Enter SkinGuard",
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.18),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    _isArabic
                                                        ? Icons.arrow_back
                                                        : Icons.arrow_forward,
                                                    color: Colors.white,
                                                    size: 19,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    // 6. TRUST INDICATORS
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildTrustItem(
                                            _isArabic ? "خصوصي" : "Private",
                                            brandTeal,
                                            mutedGrey),
                                        const SizedBox(width: 18),
                                        _buildTrustItem(
                                            _isArabic ? "سريري" : "Clinical",
                                            brandTeal,
                                            mutedGrey),
                                        const SizedBox(width: 18),
                                        _buildTrustItem(
                                            _isArabic ? "متصل" : "Connected",
                                            brandTeal,
                                            mutedGrey),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // 7. BOTTOM STATUS BAR
                            FadeTransition(
                              opacity: _footerFade,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "SG UAE / 2026",
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      width: 22,
                                      height: 1,
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    Text(
                                      _isArabic ? "جاهز" : "READY",
                                      style: const TextStyle(
                                        color: Color(0xFF16A34A),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTrustItem(String label, Color dotColor, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// CUSTOM PAINTERS: MATHEMATICAL PRECISION GRAPHICS (ZERO DEPENDENCIES)
// =========================================================================

/// Custom painter for the mini header shield
class MiniShieldPainter extends CustomPainter {
  final Color color;
  final Color accentColor;

  MiniShieldPainter({required this.color, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint shieldPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width, size.height * 0.18);
    path.quadraticBezierTo(
      size.width,
      size.height * 0.65,
      size.width * 0.5,
      size.height,
    );
    path.quadraticBezierTo(
      0,
      size.height * 0.65,
      0,
      size.height * 0.18,
    );
    path.close();
    canvas.drawPath(path, shieldPaint);

    // 4 White Dermal Arch Lines
    final Paint linePaint = Paint()
      ..color = accentColor.withOpacity(0.9)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 3; i++) {
      final double progress = i / 4.0;
      final double y = size.height * (0.35 + progress * 0.35);
      final double span = size.width * (0.2 + progress * 0.22);
      final Path linePath = Path();
      linePath.moveTo(size.width * 0.5 - span, y + 2.5);
      linePath.quadraticBezierTo(
        size.width * 0.5,
        y - 3.5,
        size.width * 0.5 + span,
        y + 2.5,
      );
      canvas.drawPath(linePath, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant MiniShieldPainter oldDelegate) => false;
}

/// Custom painter for the central diagnostic seal field:
/// - Atmospheric Pale-Mint Glow
/// - Concentric Rings with slow rotation
/// - Satellite Diagnostic Points (Red '01', Amber, Teal)
/// - Scanning laser beam
/// - Gold focus point above the shield apex
class ClinicalSealFieldPainter extends CustomPainter {
  final double rotationAngle;
  final double scanProgress;
  final double pulseScale;

  ClinicalSealFieldPainter({
    required this.rotationAngle,
    required this.scanProgress,
    required this.pulseScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2 - 12);
    final double maxR = size.width * 0.46;

    // 1. Atmospheric Pale-Mint Glow Behind Seal
    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF08766F).withOpacity(0.08),
          const Color(0xFF08766F).withOpacity(0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxR * 1.15));
    canvas.drawCircle(center, maxR * 1.15, glowPaint);

    // 2. Outer Thin Diagnostic Ring
    final Paint outerRingPaint = Paint()
      ..color = const Color(0xFF80CBC4).withOpacity(0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, maxR, outerRingPaint);

    // 3. Middle Dashed / Dotted Diagnostic Ring
    final Paint innerRingPaint = Paint()
      ..color = const Color(0xFF08766F).withOpacity(0.20)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    _drawDashedCircle(canvas, center, maxR * 0.76, innerRingPaint, 36);

    // 4. Innermost Subtle Circle
    final Paint innermostRingPaint = Paint()
      ..color = const Color(0xFF80CBC4).withOpacity(0.20)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, maxR * 0.52, innermostRingPaint);

    // 5. Rotating Satellite Diagnostic Markers
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);

    // Marker A: Red Diagnostic Node with "01" (at ~10 o'clock = ~145 degrees)
    const double redAngle = 2.5; // ~145 deg in radians
    final Offset redPos = Offset(
      maxR * 0.76 * math.cos(redAngle),
      maxR * 0.76 * math.sin(redAngle),
    );
    final Paint redPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawCircle(redPos, 3.0, redPaint);

    // Marker B: Amber Focus Dot (at ~2 o'clock)
    const double amberAngle = -0.6;
    final Offset amberPos = Offset(
      maxR * math.cos(amberAngle),
      maxR * math.sin(amberAngle),
    );
    final Paint amberPaint = Paint()..color = const Color(0xFFD97706);
    canvas.drawCircle(amberPos, 2.5, amberPaint);

    // Marker C: Healthcare Teal Dot (at ~4 o'clock)
    const double tealAngle = 1.0;
    final Offset tealPos = Offset(
      maxR * 0.76 * math.cos(tealAngle),
      maxR * 0.76 * math.sin(tealAngle),
    );
    final Paint tealPaint = Paint()..color = const Color(0xFF08766F);
    canvas.drawCircle(tealPos, 2.5, tealPaint);

    // Marker D: Muted Accent Dot (at ~8 o'clock)
    const double mutedAngle = -2.2;
    final Offset mutedPos = Offset(
      maxR * math.cos(mutedAngle),
      maxR * math.sin(mutedAngle),
    );
    final Paint mutedDotPaint = Paint()
      ..color = const Color(0xFF08766F).withOpacity(0.5);
    canvas.drawCircle(mutedPos, 2.0, mutedDotPaint);

    canvas.restore();

    // 6. Draw Fixed "01" text next to the red marker
    // Compute current unrotated position of red marker for readable text
    final double currentRedAngle = redAngle + rotationAngle;
    final Offset labelPos = Offset(
      center.dx + maxR * 0.76 * math.cos(currentRedAngle),
      center.dy + maxR * 0.76 * math.sin(currentRedAngle),
    );
    final TextPainter tp01 = TextPainter(
      text: const TextSpan(
        text: "01",
        style: TextStyle(
          color: Color(0xFFEF4444),
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp01.paint(canvas, Offset(labelPos.dx - 12, labelPos.dy - 10));

    // 7. Gold Focus Dot (Pulsing, exactly above shield apex)
    final double apexY = center.dy - 36;
    final Offset goldApexCenter = Offset(center.dx, apexY);
    final double pulseR = 3.2 + pulseScale * 1.2;

    // Soft Gold Halo
    final Paint goldHalo = Paint()
      ..color = const Color(0xFFF59E0B).withOpacity(0.25 + pulseScale * 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(goldApexCenter, pulseR * 2.2, goldHalo);

    // Solid Gold Dot
    final Paint goldDot = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(goldApexCenter, pulseR, goldDot);

    // 8. Thin Teal Scanning Beam Sweeping Over Shield
    final double scanTop = center.dy - 40;
    final double scanBottom = center.dy + 35;
    final double currentScanY = scanTop + (scanBottom - scanTop) * scanProgress;
    final double scanAlpha = math.sin(scanProgress * math.pi).clamp(0.0, 1.0);

    if (scanAlpha > 0.05) {
      final Paint scanLinePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF08766F).withOpacity(0.65 * scanAlpha),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromLTWH(center.dx - 45, currentScanY, 90, 1.2),
        )
        ..strokeWidth = 1.2;

      canvas.drawLine(
        Offset(center.dx - 45, currentScanY),
        Offset(center.dx + 45, currentScanY),
        scanLinePaint,
      );
    }
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius,
      Paint paint, int dashCount) {
    final double dashAngle = (2 * math.pi) / dashCount;
    for (int i = 0; i < dashCount; i += 2) {
      final double startAngle = i * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle * 0.7,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ClinicalSealFieldPainter oldDelegate) => true;
}

/// Custom painter for the Central Healthcare Shield with 4 Dermal Lines
class ClinicalDermalShieldPainter extends CustomPainter {
  final Color color;
  final Color accentColor;

  ClinicalDermalShieldPainter({
    required this.color,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Outer Shield Path
    final Path path = Path();
    path.moveTo(center.dx, 0);
    path.lineTo(size.width, size.height * 0.18);
    path.quadraticBezierTo(
      size.width,
      size.height * 0.65,
      center.dx,
      size.height,
    );
    path.quadraticBezierTo(
      0,
      size.height * 0.65,
      0,
      size.height * 0.18,
    );
    path.close();

    // Shield Fill: Healthcare Teal Gradient
    final Paint fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF098A82),
          Color(0xFF065F58),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Subtle Outer Stroke
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF044843).withOpacity(0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);

    // 4 Concentric White Dermal Arches (Skin Strata)
    final Paint dermalLinePaint = Paint()
      ..color = accentColor.withOpacity(0.92)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 4; i++) {
      final double fraction = i / 5.0;
      final double y = size.height * (0.34 + fraction * 0.38);
      final double span = size.width * (0.20 + fraction * 0.20);

      final Path arch = Path();
      arch.moveTo(center.dx - span, y + 4.0);
      arch.quadraticBezierTo(
        center.dx,
        y - 5.5,
        center.dx + span,
        y + 4.0,
      );
      canvas.drawPath(arch, dermalLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant ClinicalDermalShieldPainter oldDelegate) => false;
}

/// Custom painter for the waving cloth UAE Flag with realistic fabric physics
class UaeWavingClothFlagPainter extends CustomPainter {
  final double phase;

  UaeWavingClothFlagPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    const int slices = 32;
    final double sliceWidth = size.width / slices;
    final double hoistWidth = size.width * 0.26;

    // Flag Colors
    const Color red = Color(0xFFEF3340);
    const Color green = Color(0xFF159657);
    const Color white = Color(0xFFFFFFFF);
    const Color black = Color(0xFF171B1B);

    for (int i = 0; i < slices; i++) {
      final double x0 = i * sliceWidth;
      final double x1 = (i + 1) * sliceWidth;

      // Sinusoidal vertical displacement
      final double wave0 = math.sin(phase + (x0 / size.width) * 2 * math.pi) * 2.2;
      final double wave1 = math.sin(phase + (x1 / size.width) * 2 * math.pi) * 2.2;

      // Specular Light Sheen across fabric
      final double light =
          1.0 + 0.12 * math.cos(phase + (x0 / size.width) * 2 * math.pi);

      // Check Hoist (Red vertical bar on left)
      if (x0 < hoistWidth) {
        final Paint p = Paint()
          ..color = _applyShading(red, light)
          ..style = PaintingStyle.fill;
        _drawSliceQuad(canvas, x0, x1, wave0, wave1, 0, size.height, p);
      } else {
        // Fly (Green top, White middle, Black bottom)
        final double stripeH = size.height / 3;

        // 1. Green Stripe
        final Paint pg = Paint()
          ..color = _applyShading(green, light)
          ..style = PaintingStyle.fill;
        _drawSliceQuad(canvas, x0, x1, wave0, wave1, 0, stripeH, pg);

        // 2. White Stripe
        final Paint pw = Paint()
          ..color = _applyShading(white, light)
          ..style = PaintingStyle.fill;
        _drawSliceQuad(canvas, x0, x1, wave0, wave1, stripeH, stripeH * 2, pw);

        // 3. Black Stripe
        final Paint pb = Paint()
          ..color = _applyShading(black, light)
          ..style = PaintingStyle.fill;
        _drawSliceQuad(
            canvas, x0, x1, wave0, wave1, stripeH * 2, size.height, pb);
      }
    }
  }

  void _drawSliceQuad(Canvas canvas, double x0, double x1, double w0, double w1,
      double yTop, double yBottom, Paint paint) {
    final Path path = Path();
    path.moveTo(x0, yTop + w0);
    path.lineTo(x1, yTop + w1);
    path.lineTo(x1, yBottom + w1);
    path.lineTo(x0, yBottom + w0);
    path.close();
    canvas.drawPath(path, paint);
  }

  Color _applyShading(Color base, double factor) {
    final int r = (base.red * factor).clamp(0, 255).toInt();
    final int g = (base.green * factor).clamp(0, 255).toInt();
    final int b = (base.blue * factor).clamp(0, 255).toInt();
    return Color.fromARGB(base.alpha, r, g, b);
  }

  @override
  bool shouldRepaint(covariant UaeWavingClothFlagPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

/// Mini flag painter for the header identifier
class UaeFlagMiniPainter extends CustomPainter {
  final double phase;

  UaeFlagMiniPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final double hoistW = size.width * 0.28;
    final double wave = math.sin(phase) * 0.8;

    // Hoist: Red
    canvas.drawRect(
      Rect.fromLTWH(0, wave, hoistW, size.height),
      Paint()..color = const Color(0xFFEF3340),
    );

    // Fly: Green, White, Black
    final double stripeH = size.height / 3;
    final double flyW = size.width - hoistW;

    // Green
    canvas.drawRect(
      Rect.fromLTWH(hoistW, wave, flyW, stripeH),
      Paint()..color = const Color(0xFF159657),
    );

    // White
    canvas.drawRect(
      Rect.fromLTWH(hoistW, stripeH + wave, flyW, stripeH),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    // Black
    canvas.drawRect(
      Rect.fromLTWH(hoistW, stripeH * 2 + wave, flyW, stripeH),
      Paint()..color = const Color(0xFF171B1B),
    );
  }

  @override
  bool shouldRepaint(covariant UaeFlagMiniPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
