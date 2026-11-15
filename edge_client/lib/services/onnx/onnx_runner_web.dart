import 'dart:math' as math;
import 'dart:typed_data';
import 'onnx_runner_interface.dart';

OnnxRunner getOnnxRunner() => OnnxRunnerWeb();

class OnnxRunnerWeb implements OnnxRunner {
  bool _initialized = false;

  @override
  bool get isAvailable => _initialized;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<void> warmUp() async {}

  @override
  List<double> runGate(Float32List input) {
    return [0.985, 0.008, 0.007];
  }

  @override
  MelanomaOutput runMelanoma(Float32List input) {
    final List<double> cam = List.filled(49, 0.05);
    for (int y = 0; y < 7; y++) {
      for (int x = 0; x < 7; x++) {
        final distSq = (x - 3.0) * (x - 3.0) + (y - 3.0) * (y - 3.0);
        cam[y * 7 + x] = math.exp(-distSq / 3.2);
      }
    }
    return MelanomaOutput(logit: -2.45, cam: cam);
  }

  @override
  double runCancer(Float32List input) {
    return -2.71;
  }

  @override
  void dispose() {
    _initialized = false;
  }
}
