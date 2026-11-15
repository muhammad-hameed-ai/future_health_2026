import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:onnxruntime/onnxruntime.dart';
import 'onnx_runner_interface.dart';

OnnxRunner getOnnxRunner() => OnnxRunnerNative();

class OnnxRunnerNative implements OnnxRunner {
  OrtSession? _gateSession;
  OrtSession? _melanomaSession;
  OrtSession? _cancerSession;
  bool _initialized = false;

  @override
  bool get isAvailable => _initialized;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      OrtEnv.instance.init();

      final sessionOpts = OrtSessionOptions();

      final gateBytes = await rootBundle.load('assets/models/ood_gate.onnx');
      _gateSession = OrtSession.fromBuffer(
        gateBytes.buffer.asUint8List(),
        sessionOpts,
      );

      final melBytes = await rootBundle.load('assets/models/melanoma_head.onnx');
      _melanomaSession = OrtSession.fromBuffer(
        melBytes.buffer.asUint8List(),
        sessionOpts,
      );

      final canBytes = await rootBundle.load('assets/models/cancer_head.onnx');
      _cancerSession = OrtSession.fromBuffer(
        canBytes.buffer.asUint8List(),
        sessionOpts,
      );

      sessionOpts.release();
      _initialized = true;
    } catch (e) {
      debugPrint('ONNX Native initialization error: $e');
    }
  }

  @override
  Future<void> warmUp() async {
    if (!_initialized) return;
    try {
      final dummy = Float32List(1 * 3 * 224 * 224);
      runGate(dummy);
      runMelanoma(dummy);
      runCancer(dummy);
    } catch (e) {
      debugPrint('ONNX Native warmUp notice: $e');
    }
  }

  @override
  List<double> runGate(Float32List input) {
    if (_gateSession == null) return [0.99, 0.005, 0.005];

    final inputOrt = OrtValueTensor.createTensorWithDataList(
      input,
      [1, 3, 224, 224],
    );

    final outputs = _gateSession!.run(
      OrtRunOptions(),
      {'image': inputOrt},
    );

    final logits = (outputs[0]?.value as List<List<double>>)[0];
    inputOrt.release();
    for (final o in outputs) {
      o?.release();
    }

    return _softmax(logits);
  }

  @override
  MelanomaOutput runMelanoma(Float32List input) {
    if (_melanomaSession == null) {
      return const MelanomaOutput(logit: -2.0, cam: null);
    }

    final inputOrt = OrtValueTensor.createTensorWithDataList(
      input,
      [1, 3, 224, 224],
    );

    final outputs = _melanomaSession!.run(
      OrtRunOptions(),
      {'image': inputOrt},
    );

    final logitMel = _extractScalar(outputs[0]!.value);

    List<double>? cam;
    if (outputs.length > 2 && outputs[2] != null) {
      cam = _flattenToDoubles(outputs[2]!.value);
    }

    inputOrt.release();
    for (final o in outputs) {
      o?.release();
    }

    return MelanomaOutput(logit: logitMel, cam: cam);
  }

  @override
  double runCancer(Float32List input) {
    if (_cancerSession == null) return -2.0;

    final inputOrt = OrtValueTensor.createTensorWithDataList(
      input,
      [1, 3, 224, 224],
    );

    final outputs = _cancerSession!.run(
      OrtRunOptions(),
      {'image': inputOrt},
    );

    final logitCancer = _extractScalar(outputs[1]!.value);

    inputOrt.release();
    for (final o in outputs) {
      o?.release();
    }

    return logitCancer;
  }

  @override
  void dispose() {
    _gateSession?.release();
    _melanomaSession?.release();
    _cancerSession?.release();
    _gateSession = null;
    _melanomaSession = null;
    _cancerSession = null;
    _initialized = false;
  }

  static List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((l) => math.exp(l - maxLogit)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  static double _extractScalar(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is List) return _extractScalar(value[0]);
    throw ArgumentError('Cannot extract scalar from $value');
  }

  static List<double> _flattenToDoubles(dynamic value) {
    if (value is double) return [value];
    if (value is num) return [value.toDouble()];
    if (value is List) {
      return value.expand((e) => _flattenToDoubles(e)).toList();
    }
    throw ArgumentError('Cannot flatten $value');
  }
}
