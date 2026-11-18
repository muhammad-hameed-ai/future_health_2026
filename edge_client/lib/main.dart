import 'package:flutter/material.dart';
import 'screens/welcome_logo_screen.dart';
import 'services/triage_api_client.dart';
import 'services/auth_service.dart';
import 'services/inference_service.dart';
import 'services/language_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Launch the UI immediately on frame 1 — eliminating any startup delay or black screen
  runApp(const SkinGuardEdgeApp());

  // Initialize network and pre-warm neural inference engines asynchronously in background
  _initializeBackgroundServices();
}

void _initializeBackgroundServices() async {
  try {
    await LanguageService.init();
  } catch (e) {
    debugPrint('Language init notice: $e');
  }

  try {
    await TriageApiClient.initSavedHost();
  } catch (e) {
    debugPrint('Host init notice: $e');
  }

  try {
    await AuthService.initAuth();
  } catch (e) {
    debugPrint('Auth init notice: $e');
  }

  try {
    if (!InferenceService.instance.isInitialized) {
      await InferenceService.instance.initialize();
    }
    await InferenceService.instance.warmUp();
    debugPrint('Inference engine pre-warmed successfully in background.');
  } catch (e) {
    debugPrint('Inference engine pre-warm notice: $e');
  }
}

class SkinGuardEdgeApp extends StatelessWidget {
  const SkinGuardEdgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkinGuard AI • Future Health 2026',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Medical Frost White
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7), // Clinical Sky Blue
          brightness: Brightness.light,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0.5,
          scrolledUnderElevation: 1.0,
        ),
        cardTheme: const CardTheme(
          color: Colors.white,
          elevation: 0.5,
        ),
      ),
      home: const WelcomeLogoScreen(),
    );
  }
}
