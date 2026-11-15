import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'main_navigation_shell.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../services/inference_service.dart';

/// Ultra-Premium Welcome / Gateway Splash Screen for SkinGuard AI.
/// Features:
/// 1. Pure medical white background (#FFFFFF).
/// 2. Mathematically simulated 60 FPS waving UAE Flag in motion.
/// 3. Clear, unobstructed portraits of the 3 UAE leaders (shield removed)
///    smoothly floating and fading into view.
/// 4. Minimalist typography: Displays only the prestigious App Name.
/// 5. Automatic smooth transition after 3.8 seconds with ONNX model pre-warming.
class WelcomeLogoScreen extends StatefulWidget {
  const WelcomeLogoScreen({super.key});

  @override
  State<WelcomeLogoScreen> createState() => _WelcomeLogoScreenState();
}

class _WelcomeLogoScreenState extends State<WelcomeLogoScreen>
    with TickerProviderStateMixin {
  late AnimationController _flagWaveController;
  late AnimationController _entranceController;
  late AnimationController _shimmerController;

  late Animation<double> _entranceFade;
  late Animation<double> _entranceSlide;
  late Animation<double> _entranceScale;
  late Animation<double> _titleFade;

  Timer? _autoTransitionTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // 1. Continuous Flag Waving Physics Animation (3.2 second loop)
    _flagWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    // 2. Entrance Animation: Leaders and Title slowly and smoothly appear
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.85, curve: Curves.easeOutCubic),
    );

    _entranceSlide = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.90, curve: Curves.easeOutCubic),
      ),
    );

    _entranceScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.40, 1.0, curve: Curves.easeOut),
    );

    // 3. Shimmer Controller for the metallic title sheen
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // Start the entrance animation
    _entranceController.forward();

    // Pre-warm neural ONNX inference engines in background while splash is shown
    _preWarmEngines();

    // 4. Auto-dismiss / transition after 3.8 seconds
    _autoTransitionTimer = Timer(const Duration(milliseconds: 3800), () {
      _navigateToGateway();
    });
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

  @override
  void dispose() {
    _autoTransitionTimer?.cancel();
    _flagWaveController.dispose();
    _entranceController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _navigateToGateway() {
    if (!mounted || _navigated) return;
    _navigated = true;

    final Widget targetScreen = !AuthService.isAuthenticated
        ? LoginScreen(
            onLoginSuccess: () {
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const MainNavigationShell(initialIndex: 0),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 450),
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
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigateToGateway, // Allow tap-to-skip
        child: SafeArea(
          child: Stack(
            children: [
              // 1. Center Content: Waving UAE Flag + 3 Leaders + App Name
              Center(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),

                      // Animated Stage: Waving Flag + Leaders Emblem
                      SizedBox(
                        width: math.min(size.width * 0.94, 460),
                        height: 380,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Layer A: Mathematically Animated Waving UAE Flag in Motion
                            Positioned(
                              top: 20,
                              left: 15,
                              right: 15,
                              height: 250,
                              child: AnimatedBuilder(
                                animation: _flagWaveController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: UaeFlagClothPainter(
                                      wavePhase: _flagWaveController.value *
                                          2 *
                                          math.pi,
                                    ),
                                    size: const Size(double.infinity, 250),
                                  );
                                },
                              ),
                            ),

                            // Layer B: Ambient Golden Halo
                            AnimatedBuilder(
                              animation: _entranceController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: (_entranceFade.value * 0.65)
                                      .clamp(0.0, 1.0),
                                  child: Container(
                                    width: 330,
                                    height: 330,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          const Color(0xFFD4AF37)
                                              .withOpacity(0.22),
                                          const Color(0xFFD4AF37)
                                              .withOpacity(0.06),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.55, 1.0],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Layer C: 3 UAE Leaders in Arched Gold Frames (Shield Removed)
                            // Slowly and gracefully shows in front of the flag
                            AnimatedBuilder(
                              animation: _entranceController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _entranceSlide.value),
                                  child: Transform.scale(
                                    scale: _entranceScale.value,
                                    child: Opacity(
                                      opacity: _entranceFade.value,
                                      child: child,
                                    ),
                                  ),
                                );
                              },
                              child: Image.asset(
                                'assets/images/uae_welcome_emblem.png',
                                width: math.min(size.width * 0.90, 420),
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback to transparent leaders asset
                                  return Image.asset(
                                    'assets/images/uae_leaders_transparent.png',
                                    width: math.min(size.width * 0.82, 380),
                                    fit: BoxFit.contain,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 2. App Name Only: Master-level Typography
                      AnimatedBuilder(
                        animation: _titleFade,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _titleFade.value,
                            child: child,
                          );
                        },
                        child: Column(
                          children: [
                            // Main App Name
                            ShaderMask(
                              shaderCallback: (bounds) {
                                final double shift = _shimmerController.value;
                                return LinearGradient(
                                  begin: Alignment(-1.5 + (shift * 3), 0),
                                  end: Alignment(0.5 + (shift * 3), 0),
                                  colors: const [
                                    Color(0xFF0F2744), // Deep Clinical Navy
                                    Color(0xFF1E3A8A), // Royal Indigo
                                    Color(0xFFD4AF37), // Metallic UAE Gold
                                    Color(0xFF0F2744), // Deep Clinical Navy
                                  ],
                                  stops: const [0.0, 0.45, 0.55, 1.0],
                                ).createShader(bounds);
                              },
                              child: const Text(
                                'SKINGUARD AI',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.8,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Subtitle Tag
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 24,
                                  height: 1.5,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        const Color(0xFFD4AF37).withOpacity(0.8),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'TRIAGE HUB',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 6.0,
                                    color: Color(0xFFB8860B), // Metallic Bronze Gold
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 24,
                                  height: 1.5,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFD4AF37).withOpacity(0.8),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // National Healthcare Vision Emblem
                            Text(
                              'رؤية الإمارات للرعاية الصحية الوقائية ٢٠٢٦',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: const Color(0xFF64748B).withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Subtle Bottom Countdown / Engine Warm-up Line
              Positioned(
                bottom: 24,
                left: 48,
                right: 48,
                child: AnimatedBuilder(
                  animation: _entranceController,
                  builder: (context, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 3600),
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              return LinearProgressIndicator(
                                value: value,
                                minHeight: 2.2,
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFFD4AF37).withOpacity(0.85),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'INITIALIZING CLINICAL GATEWAY',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.2,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter that renders the UAE Flag with realistic 60 FPS cloth wave physics,
/// specular highlights, and natural wind flutter.
class UaeFlagClothPainter extends CustomPainter {
  final double wavePhase;

  UaeFlagClothPainter({required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double width = size.width;
    final double height = size.height;

    // Flag dimensions (2:1 official ratio centered in rect)
    final double flagW = width * 0.95;
    final double flagH = height * 0.82;
    final double startX = (width - flagW) / 2;
    final double startY = (height - flagH) / 2;

    // Official UAE Colors
    const Color uaeRed = Color(0xFFCE1126);    // Hoist vertical stripe
    const Color uaeGreen = Color(0xFF007A3D);  // Top horizontal stripe
    const Color uaeWhite = Color(0xFFF8FAFC);  // Middle horizontal stripe
    const Color uaeBlack = Color(0xFF1E293B);  // Bottom horizontal stripe

    final double hoistW = flagW * 0.25;
    final double stripeH = flagH / 3;

    // We render the flag as vertical slices across the fly with wave displacement
    const int slices = 70;
    final double dx = flagW / slices;

    for (int i = 0; i < slices; i++) {
      final double x0 = startX + i * dx;
      final double x1 = x0 + dx;

      // Distance from hoist normalized [0, 1]
      final double progress = (i / slices);

      // Waving amplitude increases towards the free fly end
      final double amp = 14.0 * math.pow(progress, 1.25);

      // Multi-harmonic sine wave for natural cloth fluttering
      final double wave1 = math.sin(progress * 2.8 * math.pi - wavePhase);
      final double wave2 =
          0.32 * math.sin(progress * 5.2 * math.pi - wavePhase * 1.5 + 0.5);
      final double yDisp = (wave1 + wave2) * amp;

      // Surface lighting slope: derivative gives normal angle for specular lighting
      final double slope = math.cos(progress * 2.8 * math.pi - wavePhase);
      final double lightFactor = (slope * 0.16).clamp(-0.25, 0.25);

      // Compute shaded colors
      Color shade(Color base) {
        if (lightFactor >= 0) {
          return Color.lerp(base, Colors.white, lightFactor)!;
        } else {
          return Color.lerp(base, Colors.black, -lightFactor)!;
        }
      }

      final Paint pRed = Paint()..color = shade(uaeRed)..style = PaintingStyle.fill;
      final Paint pGreen = Paint()..color = shade(uaeGreen)..style = PaintingStyle.fill;
      final Paint pWhite = Paint()..color = shade(uaeWhite)..style = PaintingStyle.fill;
      final Paint pBlack = Paint()..color = shade(uaeBlack)..style = PaintingStyle.fill;

      if (x0 < startX + hoistW) {
        // Red hoist column
        final Rect r = Rect.fromLTRB(x0, startY + yDisp, x1, startY + flagH + yDisp);
        canvas.drawRect(r, pRed);
      } else {
        // Fly stripes: Green (top), White (mid), Black (bottom)
        final Rect rGreen = Rect.fromLTRB(x0, startY + yDisp, x1, startY + stripeH + yDisp);
        final Rect rWhite = Rect.fromLTRB(x0, startY + stripeH + yDisp, x1, startY + 2 * stripeH + yDisp);
        final Rect rBlack = Rect.fromLTRB(x0, startY + 2 * stripeH + yDisp, x1, startY + flagH + yDisp);

        canvas.drawRect(rGreen, pGreen);
        canvas.drawRect(rWhite, pWhite);
        canvas.drawRect(rBlack, pBlack);
      }
    }
  }

  @override
  bool shouldRepaint(covariant UaeFlagClothPainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase;
  }
}
