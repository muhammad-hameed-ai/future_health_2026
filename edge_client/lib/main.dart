import 'package:flutter/material.dart';
import 'screens/welcome_logo_screen.dart';
import 'services/triage_api_client.dart';
import 'services/auth_service.dart';
import 'services/inference_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TriageApiClient.initSavedHost();
  await AuthService.initAuth();
  try {
    await InferenceService.instance.initialize();
    await InferenceService.instance.warmUp();
  } catch (e) {
    debugPrint('Inference engine pre-warm notice: $e');
  }
  runApp(const SkinGuardEdgeApp());
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
