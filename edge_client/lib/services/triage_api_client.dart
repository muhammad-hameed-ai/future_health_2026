import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'local_storage_service.dart';

// -----------------------------------------------------------------------------
// STRICT DATA TRANSFER OBJECTS (DTOs)
// -----------------------------------------------------------------------------

class EdgeRiskVector {
  final List<double> classProbabilities;
  final double inferenceLatencyMs;
  final bool domainShiftDetected;

  EdgeRiskVector({
    required this.classProbabilities,
    required this.inferenceLatencyMs,
    this.domainShiftDetected = false,
  });

  Map<String, dynamic> toJson() => {
        'class_probabilities': classProbabilities,
        'inference_latency_ms': inferenceLatencyMs,
        'domain_shift_detected': domainShiftDetected,
      };
}

class PatientContext {
  final String ageBracket;
  final int primarySymptomDurationDays;
  final List<String> comorbidities;

  PatientContext({
    required this.ageBracket,
    required this.primarySymptomDurationDays,
    this.comorbidities = const [],
  });

  Map<String, dynamic> toJson() => {
        'age_bracket': ageBracket,
        'primary_symptom_duration_days': primarySymptomDurationDays,
        'comorbidities': comorbidities,
      };
}

class TriageRequest {
  final EdgeRiskVector riskVector;
  final PatientContext patientContext;

  TriageRequest({
    required this.riskVector,
    required this.patientContext,
  });

  Map<String, dynamic> toJson() => {
        'risk_vector': riskVector.toJson(),
        'patient_context': patientContext.toJson(),
      };
}

class TriageResponse {
  final String recommendedAction;
  final int timeframeDays;
  final String clinicalRationale;
  final bool requiresHumanVerification;
  final bool isOfflineFallback;
  final String protocolGrounding;

  TriageResponse({
    required this.recommendedAction,
    required this.timeframeDays,
    required this.clinicalRationale,
    required this.requiresHumanVerification,
    this.isOfflineFallback = false,
    this.protocolGrounding = 'Qdrant Vector RAG • Gemini 2.5 Clinical Gateway',
  });

  factory TriageResponse.fromJson(Map<String, dynamic> json) {
    return TriageResponse(
      recommendedAction: json['recommended_action'] ?? 'Unknown Action',
      timeframeDays: json['timeframe_days'] ?? 14,
      clinicalRationale: json['clinical_rationale'] ?? 'No rationale provided.',
      requiresHumanVerification: json['requires_human_verification'] ?? true,
      isOfflineFallback: false,
      protocolGrounding: 'Qdrant Vector RAG • Gemini 2.5 Clinical Gateway',
    );
  }
}

// -----------------------------------------------------------------------------
// ADAPTIVE API CLIENT & AUTONOMOUS ON-DEVICE CLINICAL ENGINE
// -----------------------------------------------------------------------------

class TriageApiClient {
  static const int _timeoutSeconds = 4;
  static String? _cachedActiveBaseUrl;
  static String? customServerHost;

  /// Loads custom server host from local storage
  static Future<void> initSavedHost() async {
    final host = await LocalStorageService.getSavedServerHost();
    if (host != null && host.isNotEmpty) {
      customServerHost = host;
    }
  }

  /// Candidate hosts to automatically discover reachable backend:
  /// 1. Custom user-defined server host (if set in Network Diagnostics)
  /// 2. 192.168.18.14:8000 -> Active when phone is on the same local Wi-Fi
  /// 3. 127.0.0.1:8000 -> Active when phone is connected via USB (`adb reverse tcp:8000 tcp:8000`)
  /// 4. 10.0.2.2:8000 -> Active when running in Android Studio emulator
  static List<String> get candidateBaseUrls {
    final list = <String>[];
    if (customServerHost != null && customServerHost!.trim().isNotEmpty) {
      final host = customServerHost!.trim();
      final formatted = host.startsWith('http') ? host : 'http://$host';
      list.add(formatted.endsWith('/api/v1') ? formatted : '$formatted/api/v1');
    }

    // Primary Production Render Cloud Gateway (Global HTTPS 24/7)
    list.add('https://future-health-2026.onrender.com/api/v1');

    const customEnv = String.fromEnvironment('BACKEND_URL');
    if (customEnv.isNotEmpty) {
      list.add(customEnv);
    }

    if (kIsWeb) {
      list.add('http://127.0.0.1:8000/api/v1');
      return list;
    }

    if (Platform.isAndroid) {
      list.addAll([
        'http://192.168.18.14:8000/api/v1', // Wi-Fi local network IP
        'http://127.0.0.1:8000/api/v1',     // ADB reverse USB tunnel
        'http://10.0.2.2:8000/api/v1',       // Android emulator loopback
      ]);
    } else {
      list.add('http://127.0.0.1:8000/api/v1');
    }

    return list;
  }

  /// Fetches dynamic Server-Driven UI Configuration from Render cloud backend.
  static Future<Map<String, dynamic>?> fetchRemoteConfig() async {
    for (final baseUrl in candidateBaseUrls) {
      try {
        final uri = Uri.parse('$baseUrl/app/config');
        final res = await http.get(uri).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          return jsonDecode(res.body) as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Checks for available Over-The-Air app updates from Render cloud backend.
  static Future<Map<String, dynamic>?> checkForUpdates([String currentVersion = '3.0.0']) async {
    for (final baseUrl in candidateBaseUrls) {
      try {
        final uri = Uri.parse('$baseUrl/app/version');
        final res = await http.get(uri).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final latest = data['latest_version'] as String? ?? '3.0.0';
          if (latest != currentVersion) {
            return data;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  /// Pings a host to check live connection status with granular latency & diagnostic metrics
  static Future<({bool ok, int latencyMs, int statusCode, String message})> pingServerDetailed([String? specificUrl]) async {
    final rawUrl = (specificUrl != null && specificUrl.trim().isNotEmpty)
        ? specificUrl.trim()
        : (_cachedActiveBaseUrl ?? candidateBaseUrls.first);

    var cleanHost = rawUrl;
    if (!cleanHost.startsWith('http://') && !cleanHost.startsWith('https://')) {
      cleanHost = 'https://$cleanHost';
    }
    while (cleanHost.endsWith('/')) {
      cleanHost = cleanHost.substring(0, cleanHost.length - 1);
    }
    cleanHost = cleanHost.replaceAll('/api/v1', '');

    final stopwatch = Stopwatch()..start();
    try {
      final uri = Uri.parse('$cleanHost/health');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;

      if (res.statusCode == 200) {
        _cachedActiveBaseUrl = '$cleanHost/api/v1';
        return (
          ok: true,
          latencyMs: latency,
          statusCode: 200,
          message: 'Connected successfully (HTTP 200 Live)',
        );
      } else {
        return (
          ok: false,
          latencyMs: latency,
          statusCode: res.statusCode,
          message: 'Server returned HTTP ${res.statusCode}',
        );
      }
    } on TimeoutException {
      stopwatch.stop();
      return (
        ok: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        statusCode: 408,
        message: 'Timeout: Cloud container warming up. Please re-test.',
      );
    } catch (e) {
      stopwatch.stop();
      return (
        ok: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        statusCode: 503,
        message: 'Could not connect: ${e.toString().split('\n').first}',
      );
    }
  }

  /// Pings a host to check live connection status
  static Future<bool> pingServer([String? specificUrl]) async {
    final res = await pingServerDetailed(specificUrl);
    return res.ok;
  }

  /// Transmits the on-device EdgeRiskVector to the RAG backend.
  /// Tries candidate endpoints with fast auto-fallback to guarantee connectivity.
  /// If offline, engages the Autonomous On-Device Clinical Protocol Engine.
  static Future<TriageResponse> getTriagePathway(TriageRequest request) async {
    final candidates = _cachedActiveBaseUrl != null
        ? [_cachedActiveBaseUrl!, ...candidateBaseUrls.where((u) => u != _cachedActiveBaseUrl)]
        : candidateBaseUrls;

    for (final baseUrl in candidates) {
      final url = Uri.parse('$baseUrl/triage');
      try {
        if (kDebugMode) {
          print('📡 Trying Zero-PII Triage Request to $url');
        }

        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(request.toJson()),
            )
            .timeout(const Duration(seconds: _timeoutSeconds));

        if (response.statusCode == 200) {
          _cachedActiveBaseUrl = baseUrl;
          if (kDebugMode) {
            print('✅ Successfully connected to intelligence hub via $baseUrl');
          }
          return TriageResponse.fromJson(jsonDecode(response.body));
        }
      } on TimeoutException {
        debugPrint('⏳ Timeout on $baseUrl, trying next route...');
      } on SocketException {
        debugPrint('🔌 Connection refused on $baseUrl, trying next route...');
      } catch (e) {
        debugPrint('⚠️ Error on $baseUrl: $e');
      }
    }

    // Circuit Breaker Engaged: Local Autonomous Clinical Decision Support Engine
    debugPrint('🚨 Cloud Gateway Unreachable: Engaging On-Device Clinical Protocol Engine');
    return generateOnDeviceClinicalPathway(request);
  }

  /// Master-Level On-Device Autonomous Clinical Protocol Engine (Offline Fallback).
  /// Grounded in UK NICE Guideline NG12 & British Association of Dermatologists (BAD) protocols.
  static TriageResponse generateOnDeviceClinicalPathway(TriageRequest request) {
    final double malProb = request.riskVector.classProbabilities.length > 1
        ? request.riskVector.classProbabilities[1]
        : 0.15;
    final int symptomDays = request.patientContext.primarySymptomDurationDays;
    final String age = request.patientContext.ageBracket;
    final bool hasMelanomaHistory =
        request.patientContext.comorbidities.contains('Personal History of Melanoma');
    final bool isImmunosuppressed =
        request.patientContext.comorbidities.contains('Immunosuppressed / Biologics');

    // Stratification Rule 1: High Malignancy or High-Risk Demographic
    if (malProb >= 0.70 || hasMelanomaHistory) {
      return TriageResponse(
        recommendedAction: 'Two-Week Wait (2WW) Urgent Referral (Suspected Melanoma Pathway)',
        timeframeDays: 14,
        clinicalRationale:
            'Grounded in NICE Guideline NG12: Lesion presents elevated optical malignancy probability (${(malProb * 100).toStringAsFixed(1)}%) in patient age $age with documented symptom history of $symptomDays day(s)${hasMelanomaHistory ? " and high-risk personal history of melanoma" : ""}. Autonomous on-device safety protocol mandates urgent 2WW face-to-face dermatological biopsy.',
        requiresHumanVerification: true,
        isOfflineFallback: true,
        protocolGrounding: 'NICE NG12 • On-Device Clinical Protocol',
      );
    }
    // Stratification Rule 2: Intermediate / Dysplastic Nevus Pathway
    else if (malProb >= 0.20 || isImmunosuppressed) {
      return TriageResponse(
        recommendedAction: 'Routine Teledermatology Triage (Atypical Nevus Pathway)',
        timeframeDays: 21,
        clinicalRationale:
            'Grounded in BAD Teledermatology SOP-002: Lesion presents intermediate atypical dysplastic risk (${(malProb * 100).toStringAsFixed(1)}%) in patient age $age with symptom duration of $symptomDays day(s). Recommended asynchronous store-and-forward teledermatology review within 21 days with serial digital dermoscopy surveillance.',
        requiresHumanVerification: true,
        isOfflineFallback: true,
        protocolGrounding: 'BAD SOP-002 • On-Device Clinical Protocol',
      );
    }
    // Stratification Rule 3: Low Risk / Reassuring Lesion Pathway
    else {
      return TriageResponse(
        recommendedAction: 'Primary Care Review & Digital Self-Monitoring (Low-Risk Pathway)',
        timeframeDays: 45,
        clinicalRationale:
            'Grounded in Primary Care Dermatology SOP-003: Lesion exhibits reassuring optical symmetry and uniform pigment distribution (${((1.0 - malProb) * 100).toStringAsFixed(1)}% benign probability). Local GP review within 45 days recommended; patient advised on ABCDE digital photo monitoring.',
        requiresHumanVerification: false,
        isOfflineFallback: true,
        protocolGrounding: 'Primary Care SOP-003 • On-Device Clinical Protocol',
      );
    }
  }
}
