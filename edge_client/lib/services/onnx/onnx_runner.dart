import 'onnx_runner_interface.dart';
import 'onnx_runner_web.dart'
    if (dart.library.io) 'onnx_runner_native.dart';

export 'onnx_runner_interface.dart';

OnnxRunner createOnnxRunner() => getOnnxRunner();
