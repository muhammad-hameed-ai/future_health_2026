import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class DermatoscopeCameraScreen extends StatefulWidget {
  const DermatoscopeCameraScreen({super.key});

  @override
  State<DermatoscopeCameraScreen> createState() => _DermatoscopeCameraScreenState();
}

class _DermatoscopeCameraScreenState extends State<DermatoscopeCameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  String? _errorMessage;

  double _zoomLevel = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 4.0;
  FlashMode _flashMode = FlashMode.auto;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No camera sensors detected on device.';
        });
        return;
      }

      // Default to primary back camera
      final backCamera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = min(4.0, await controller.getMaxZoomLevel());
      await controller.setFlashMode(_flashMode);

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Camera initialization failed: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _setZoom(double zoom) async {
    if (_controller == null || !_isInitialized) return;
    try {
      final clamped = zoom.clamp(_minZoom, _maxZoom);
      await _controller!.setZoomLevel(clamped);
      setState(() => _zoomLevel = clamped);
    } catch (e) {
      debugPrint('Zoom setting error: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_isInitialized) return;
    try {
      final FlashMode nextMode;
      switch (_flashMode) {
        case FlashMode.auto:
          nextMode = FlashMode.always;
          break;
        case FlashMode.always:
          nextMode = FlashMode.off;
          break;
        case FlashMode.off:
          nextMode = FlashMode.auto;
          break;
        default:
          nextMode = FlashMode.auto;
      }
      await _controller!.setFlashMode(nextMode);
      setState(() => _flashMode = nextMode);
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final XFile photo = await _controller!.takePicture();
      final bytes = await photo.readAsBytes();
      final img.Image? decoded = img.decodeImage(bytes);

      if (decoded != null) {
        // Crop central circular dermatoscope area (square aspect ratio)
        final int side = min(decoded.width, decoded.height);
        final int cropX = (decoded.width - side) ~/ 2;
        final int cropY = (decoded.height - side) ~/ 2;

        final img.Image squareCropped = img.copyCrop(
          decoded,
          x: cropX,
          y: cropY,
          width: side,
          height: side,
        );

        final tempDir = await getTemporaryDirectory();
        final finalPath = '${tempDir.path}/derm_capture_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedFile = File(finalPath);
        await savedFile.writeAsBytes(img.encodeJpg(squareCropped, quality: 96));

        if (!mounted) return;
        Navigator.pop(context, savedFile);
      } else {
        if (!mounted) return;
        Navigator.pop(context, File(photo.path));
      }
    } catch (e) {
      debugPrint('Photo capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 98,
      );
      if (picked != null && mounted) {
        Navigator.pop(context, File(picked.path));
      }
    } catch (e) {
      debugPrint('Gallery picker error: $e');
    }
  }

  Future<void> _fallbackNativeCamera() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 98,
      );
      if (picked != null && mounted) {
        Navigator.pop(context, File(picked.path));
      }
    } catch (e) {
      debugPrint('Native camera fallback error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Dermatoscope Camera', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt_outlined, color: Colors.amber, size: 54),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _fallbackNativeCamera,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                  icon: const Icon(Icons.photo_camera, color: Colors.white),
                  label: const Text('Open System Camera', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final double apertureDiameter = min(size.width * 0.78, 290.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Preview
          CameraPreview(_controller!),

          // 2. Dark Frosted Mask with Central Circular Cutout
          CustomPaint(
            size: Size.infinite,
            painter: _CameraDermatoscopeAperturePainter(apertureDiameter: apertureDiameter),
          ),

          // 3. Circular Guidance Text & Reticle
          Positioned(
            top: (size.height / 2) - (apertureDiameter / 2) - 65,
            left: 20,
            right: 20,
            child: const Column(
              children: [
                Text(
                  '— Fill the circle —',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Centre the mole or spot inside the circle',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),

          // 4. Macro Zoom Control Pills Bar (above the shutter)
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildZoomButton(1.0, '1.0x'),
                    const SizedBox(width: 8),
                    _buildZoomButton(1.5, '1.5x'),
                    const SizedBox(width: 8),
                    _buildZoomButton(2.0, '2.0x'),
                    const SizedBox(width: 8),
                    _buildZoomButton(2.5, '2.5x'),
                  ],
                ),
              ),
            ),
          ),

          // 5. Top Navigation & Flash Toolbar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                IconButton(
                  icon: Icon(
                    _flashMode == FlashMode.auto
                        ? Icons.flash_auto_rounded
                        : (_flashMode == FlashMode.always
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded),
                    color: _flashMode == FlashMode.off ? Colors.white54 : Colors.amberAccent,
                    size: 26,
                  ),
                  onPressed: _toggleFlash,
                ),
              ],
            ),
          ),

          // 6. Bottom Capture & Gallery Bar
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Gallery Button
                  IconButton(
                    icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 30),
                    tooltip: 'Select from Gallery',
                    onPressed: _pickFromGallery,
                  ),

                  // Big Circular Shutter Button
                  GestureDetector(
                    onTap: _isCapturing ? null : _takePicture,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4.5),
                        color: Colors.transparent,
                      ),
                      child: Center(
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isCapturing ? const Color(0xFF38BDF8) : Colors.white,
                          ),
                          child: _isCapturing
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),

                  // Native Camera Fallback Shortcut
                  IconButton(
                    icon: const Icon(Icons.flip_camera_android_rounded, color: Colors.white70, size: 28),
                    tooltip: 'System Camera',
                    onPressed: _fallbackNativeCamera,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomButton(double zoom, String label) {
    final bool isSelected = (_zoomLevel - zoom).abs() < 0.15;
    return GestureDetector(
      onTap: () => _setZoom(zoom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// Dark Frosted Mask Painter with Center Circular Cutout & Dashed Reticle
class _CameraDermatoscopeAperturePainter extends CustomPainter {
  final double apertureDiameter;

  _CameraDermatoscopeAperturePainter({required this.apertureDiameter});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = apertureDiameter / 2;

    // 1. Draw darkened frosted vignette mask outside circular center
    final maskPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;

    final maskPaint = Paint()
      ..color = const Color(0xCC000000) // 80% opacity dark vignette
      ..style = PaintingStyle.fill;
    canvas.drawPath(maskPath, maskPaint);

    // 2. Dashed Circular White Border (exact match to user's old app)
    final dashedPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    const int dashCount = 36;
    const double dashAngle = (2 * pi) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      if (i % 2 == 0) {
        final startAngle = i * dashAngle;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          dashAngle * 0.65,
          false,
          dashedPaint,
        );
      }
    }

    // 3. Subtle Center Crosshairs
    final crosshairPaint = Paint()
      ..color = const Color(0x9938BDF8)
      ..strokeWidth = 1.2;
    const ch = 12.0;
    canvas.drawLine(Offset(center.dx - ch, center.dy), Offset(center.dx + ch, center.dy), crosshairPaint);
    canvas.drawLine(Offset(center.dx, center.dy - ch), Offset(center.dx, center.dy + ch), crosshairPaint);
    canvas.drawCircle(center, 2.5, Paint()..color = const Color(0xFF38BDF8)..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _CameraDermatoscopeAperturePainter oldDelegate) {
    return oldDelegate.apertureDiameter != apertureDiameter;
  }
}

