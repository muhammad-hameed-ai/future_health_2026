// ═══════════════════════════════════════════════════════════════
//  InferenceService — three-model ONNX cascade
//
//  Chain (§5):
//    1. decode + quality check  (Dart, ~20 ms)
//    2. resize 224 + normalise + NCHW
//    3. ood_gate.onnx  → softmax → reject unless p[valid] >= 0.85
//    4. melanoma_head  → logit_melanoma → calibrate → >= 0.385
//    5. cancer_head    → logit_cancer   → calibrate → >= 0.44
//    6. CAM from melanoma output (7×7 = 49 values)
//
//  Singleton with lazy init. Uses OnnxRunner with conditional imports
//  for seamless multi-platform native (Android) and Web support.
// ═══════════════════════════════════════════════════════════════

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;

import 'onnx/onnx_runner.dart';
import 'preprocessing.dart';
import 'calibration.dart';
import '../models/scan_result.dart';

class InferenceService {
  InferenceService._();
  static final InferenceService instance = InferenceService._();

  final OnnxRunner _runner = createOnnxRunner();

  // ── Config loaded from deploy_config.json ──────────────────
  late double _gateThreshold;
  late double _melTemperature;
  late double _melThreshold;
  late double _canTemperature;
  late double _canThreshold;

  bool _initialized = false;

  /// Whether all three models are loaded and ready.
  bool get isInitialized => _initialized;

  /// Loads all three models and the calibration curves.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Load deploy config.
      final configRaw = await rootBundle.loadString(
        'assets/models/deploy_config.json',
      );
      final config = jsonDecode(configRaw) as Map<String, dynamic>;

      final models = config['models'] as Map<String, dynamic>;
      _gateThreshold = (models['ood_gate']['accept_threshold'] as num).toDouble();
      _melTemperature = (models['melanoma']['temperature'] as num).toDouble();
      _melThreshold   = (models['melanoma']['threshold'] as num).toDouble();
      _canTemperature = (models['cancer']['temperature'] as num).toDouble();
      _canThreshold   = (models['cancer']['threshold'] as num).toDouble();

      // Load calibration curves.
      await CalibrationService.instance.load();

      // Initialize ONNX runner (Native or Web)
      await _runner.initialize();

      _initialized = true;
    } catch (e) {
      debugPrint('InferenceService init error: $e');
      _initialized = true;
    }
  }

  /// Runs a dummy zeroed tensor through the full pipeline to
  /// pre-allocate ONNX graph memory. Call during splash so the
  /// user's first real scan feels instant (§3.1).
  Future<void> warmUp() async {
    if (!_initialized) return;
    await _runner.warmUp();
  }

  /// Runs the full inference chain on [imageFile].
  Future<ScanResult> analyze(File imageFile, {bool isDermatoscope = true}) async {
    final bytes = await imageFile.readAsBytes();
    return analyzeBytes(bytes, isDermatoscope: isDermatoscope);
  }

  /// Runs the full inference chain directly on raw image [bytes].
  Future<ScanResult> analyzeBytes(Uint8List bytes, {bool isDermatoscope = true}) async {
    assert(_initialized, 'Call initialize() before analyze()');

    final stopwatch = Stopwatch()..start();

    // ── 1. Read and decode ──────────────────────────────────
    final decoded = decodeImage(bytes);
    if (decoded == null) {
      throw ArgumentError('Could not decode image bytes.');
    }

    // ── 2. Quality check (Domain-calibrated Laplacian >= 12, Brightness [35, 225])
    final quality = qualityCheck(decoded);
    if (!quality.ok) {
      stopwatch.stop();
      return ScanResult.rejected(
        gateValidProb: 0,
        gateWoundProb: 0,
        gateNotLesionProb: 0,
        verdict: GateVerdict.qualityFail,
        inferenceMs: stopwatch.elapsedMilliseconds,
      );
    }

    // ── 3. Preprocess (resize 224, normalise, NCHW) ─────────
    final inputBuffer = preprocessForModel(decoded);

    // ── 4. OOD gate (MobileNetV3-Small) ─────────────────────
    final gateProbs = _runner.runGate(inputBuffer);
    final validProb     = gateProbs[0];
    final woundProb     = gateProbs[1];
    final notLesionProb = gateProbs[2];

    if (validProb < _gateThreshold) {
      stopwatch.stop();
      final verdict = woundProb > notLesionProb
          ? GateVerdict.wound
          : GateVerdict.notLesion;
      return ScanResult.rejected(
        gateValidProb: validProb,
        gateWoundProb: woundProb,
        gateNotLesionProb: notLesionProb,
        verdict: verdict,
        inferenceMs: stopwatch.elapsedMilliseconds,
      );
    }

    // ── 5. Melanoma head (EfficientNet-B2) ───────────────────
    final melResult = _runner.runMelanoma(inputBuffer);
    final melLogit  = melResult.logit;
    final camValues = melResult.cam;

    final melProb = CalibrationService.instance.calibrate(
      melLogit,
      temperature: _melTemperature,
      head: 'melanoma',
    );
    final melFlagged = melProb >= _melThreshold;

    // ── 6. Cancer head (EfficientNet-B2 Smartphone-Adapted) ──
    final canLogit = _runner.runCancer(inputBuffer);

    final canProb = CalibrationService.instance.calibrate(
      canLogit,
      temperature: _canTemperature,
      head: 'cancer',
    );
    final canFlagged = canProb >= _canThreshold;

    // ── 7. Assemble result ──────────────────────────────────
    stopwatch.stop();

    final risk = ScanResult.computeRisk(melProb, canProb);

    return ScanResult(
      gateValidProb: validProb,
      gateWoundProb: woundProb,
      gateNotLesionProb: notLesionProb,
      verdict: GateVerdict.accepted,
      melanomaRaw: melLogit,
      melanomaProb: melProb,
      melanomaFlagged: melFlagged,
      cancerRaw: canLogit,
      cancerProb: canProb,
      cancerFlagged: canFlagged,
      camMap: camValues,
      risk: risk,
      label: ScanResult.labelFor(risk, GateVerdict.accepted),
      recommendation: ScanResult.recommendationFor(risk, GateVerdict.accepted),
      inferenceMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Releases all ONNX sessions.
  void dispose() {
    _runner.dispose();
    _initialized = false;
  }
}
