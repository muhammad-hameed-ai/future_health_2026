import 'dart:typed_data';

class MelanomaOutput {
  final double logit;
  final List<double>? cam;
  const MelanomaOutput({required this.logit, this.cam});
}

abstract class OnnxRunner {
  bool get isAvailable;
  Future<void> initialize();
  Future<void> warmUp();
  List<double> runGate(Float32List input);
  MelanomaOutput runMelanoma(Float32List input);
  double runCancer(Float32List input);
  void dispose();
}
