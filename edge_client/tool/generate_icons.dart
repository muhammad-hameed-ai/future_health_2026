// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  final sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  for (final entry in sizes.entries) {
    final folder = entry.key;
    final size = entry.value;

    final image = img.Image(width: size, height: size);
    final center = size / 2.0;
    final radius = size * 0.46;

    // Draw Dark Medical Background with Soft Gradient
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final dx = x - center;
        final dy = y - center;
        final dist = sqrt(dx * dx + dy * dy);

        if (dist <= radius) {
          // Radial Gradient from #0369A1 (center) to #0F172A (edge)
          final normDist = dist / radius;
          final r = (15 * normDist + 3 * (1 - normDist)).toInt();
          final g = (23 * normDist + 105 * (1 - normDist)).toInt();
          final b = (42 * normDist + 161 * (1 - normDist)).toInt();
          image.setPixelRgba(x, y, r, g, b, 255);
        } else if (dist <= radius + 1.5) {
          // Anti-aliased boundary
          final alpha = ((radius + 1.5 - dist) * 255).clamp(0, 255).toInt();
          image.setPixelRgba(x, y, 15, 23, 42, alpha);
        } else {
          image.setPixelRgba(x, y, 0, 0, 0, 0); // Transparent
        }
      }
    }

    // Outer Reticle Ring (Cyan #38BDF8)
    final ringRadius = size * 0.36;
    final ringWidth = max(1.5, size * 0.025);
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final dist = sqrt(pow(x - center, 2) + pow(y - center, 2));
        if ((dist - ringRadius).abs() < ringWidth) {
          image.setPixelRgba(x, y, 56, 189, 248, 240);
        }
      }
    }

    // Inner Clinical Shield / Lesion Ring (Emerald #10B981)
    final innerRadius = size * 0.22;
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final dist = sqrt(pow(x - center, 2) + pow(y - center, 2));
        if (dist <= innerRadius) {
          final coreFade = 1.0 - (dist / innerRadius);
          final r = (16 + 30 * coreFade).toInt();
          final g = (185 + 50 * coreFade).clamp(0, 255).toInt();
          final b = (129 + 60 * coreFade).clamp(0, 255).toInt();
          image.setPixelRgba(x, y, r, g, b, 245);
        }
      }
    }

    // Reticle Crosshairs (4 cardinal ticks)
    final tickLength = size * 0.12;
    final tickWidth = max(1, (size * 0.03).toInt());
    final cInt = center.toInt();

    for (int t = (size * 0.08).toInt(); t < (size * 0.08 + tickLength).toInt(); t++) {
      for (int w = -tickWidth ~/ 2; w <= tickWidth ~/ 2; w++) {
        // Top
        image.setPixelRgba(cInt + w, t, 56, 189, 248, 255);
        // Bottom
        image.setPixelRgba(cInt + w, size - 1 - t, 56, 189, 248, 255);
        // Left
        image.setPixelRgba(t, cInt + w, 56, 189, 248, 255);
        // Right
        image.setPixelRgba(size - 1 - t, cInt + w, 56, 189, 248, 255);
      }
    }

    // Save PNG
    final outPath = 'android/app/src/main/res/$folder/ic_launcher.png';
    final outFile = File(outPath);
    outFile.parent.createSync(recursive: true);
    outFile.writeAsBytesSync(img.encodePng(image));
    print('Generated icon: $outPath ($size x $size)');
  }

  print('All Android app icons generated successfully!');
}
