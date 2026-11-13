import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:edge_client/services/edge_classifier.dart';

void main() {
  group('Master EdgeClassifier Cutaneous Tissue & Lesion Guardrail Tests', () {
    test('Correctly rejects non-skin surface (e.g. black laptop keyboard)', () async {
      final image = img.Image(width: 224, height: 224);
      // Fill with dark keyboard plastic (R=35, G=35, B=38) with step key outlines
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          if (x % 30 == 0 || y % 30 == 0) {
            image.setPixelRgb(x, y, 10, 10, 10);
          } else {
            image.setPixelRgb(x, y, 35, 35, 38);
          }
        }
      }
      final bytes = img.encodeJpg(image);
      final result = await EdgeClassifier.analyzeImageBytes(bytes);

      expect(result.isCutaneousTissue, isFalse);
      expect(result.malignantProbability, equals(0.0));
      expect(result.skinCoverageRatio, lessThan(0.20));
      expect(result.targetRejectionCategory, equals('NON_CUTANEOUS_SURFACE'));
    });

    test('Correctly rejects flat synthetic surface (e.g. painted drywall / paper)', () async {
      final image = img.Image(width: 224, height: 224);
      // Uniform beige paint with 0 texture
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          image.setPixelRgb(x, y, 195, 160, 130);
        }
      }
      final bytes = img.encodeJpg(image);
      final result = await EdgeClassifier.analyzeImageBytes(bytes);

      expect(result.isCutaneousTissue, isFalse);
      expect(result.malignantProbability, equals(0.0));
      expect(result.targetRejectionCategory, isIn(['NON_CUTANEOUS_SURFACE', 'NO_LESION_FOUND']));
    });

    test('Correctly rejects uniform non-lesional surface (e.g. wood desk or plain sheet)', () async {
      final image = img.Image(width: 224, height: 224);
      // Unidirectional woodgrain pattern with NO lesion
      for (int y = 0; y < 224; y++) {
        final grain = (12 * sin(y / 4.0)).toInt();
        for (int x = 0; x < 224; x++) {
          image.setPixelRgb(x, y, 135 + grain, 90 + grain ~/ 2, 60 + grain ~/ 3);
        }
      }
      final bytes = img.encodeJpg(image);
      final result = await EdgeClassifier.analyzeImageBytes(bytes);

      expect(result.isCutaneousTissue, isFalse);
      expect(result.malignantProbability, equals(0.0));
      expect(result.targetRejectionCategory, isIn(['NON_CUTANEOUS_SURFACE', 'NO_LESION_FOUND']));
    });

    // =========================================================================
    // CRITICAL TEST: Red carpet / room scene photograph
    // =========================================================================
    test('Correctly rejects red carpet / room scene photograph', () async {
      final image = img.Image(width: 224, height: 224);
      final rng = Random(77);
      // Bottom 60%: red/maroon carpet pattern (R=165, G=30, B=25 — high saturation)
      for (int y = 100; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final noise = rng.nextInt(20) - 10;
          image.setPixelRgb(
            x, y,
            (165 + noise).clamp(0, 255),
            (30 + noise ~/ 3).clamp(0, 255),
            (25 + noise ~/ 4).clamp(0, 255),
          );
        }
      }
      // Top 30%: gray wall / furniture (R=120, G=120, B=125)
      for (int y = 0; y < 70; y++) {
        for (int x = 0; x < 224; x++) {
          final noise = rng.nextInt(10) - 5;
          image.setPixelRgb(x, y, 120 + noise, 120 + noise, 125 + noise);
        }
      }
      // Middle band: darker cable/cord objects (R=20, G=20, B=22)
      for (int y = 70; y < 100; y++) {
        for (int x = 0; x < 224; x++) {
          if (x % 5 < 3) {
            image.setPixelRgb(x, y, 20, 20, 22); // black cables
          } else {
            image.setPixelRgb(x, y, 150, 35, 30); // carpet visible between
          }
        }
      }
      final bytes = img.encodeJpg(image);
      final result = await EdgeClassifier.analyzeImageBytes(bytes);

      expect(result.isCutaneousTissue, isFalse,
          reason: 'Red carpet / room scene must NEVER pass as cutaneous tissue');
      expect(result.malignantProbability, equals(0.0));
      expect(result.targetRejectionCategory,
          isIn(['NON_CUTANEOUS_SURFACE', 'SCENE_PHOTO']));
    });

    test('Correctly rejects tan/warm carpet filling the frame', () async {
      final image = img.Image(width: 224, height: 224);
      final rng = Random(99);
      // Full-frame warm tan carpet (R=190, G=120, B=80 — similar to skin but high saturation)
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final noise = rng.nextInt(14) - 7;
          // Carpet weave pattern: slight regular texture every 4 pixels
          final weave = (x % 4 == 0 || y % 4 == 0) ? -12 : 0;
          image.setPixelRgb(
            x, y,
            (190 + noise + weave).clamp(0, 255),
            (120 + noise ~/ 2 + weave).clamp(0, 255),
            (80 + noise ~/ 3 + weave).clamp(0, 255),
          );
        }
      }
      final bytes = img.encodeJpg(image);
      final result = await EdgeClassifier.analyzeImageBytes(bytes);

      expect(result.isCutaneousTissue, isFalse,
          reason: 'Tan carpet must be rejected (no focal lesion present)');
      expect(result.malignantProbability, equals(0.0));
    });

    test('Correctly rejects blue jeans / denim fabric', () async {
      final image = img.Image(width: 224, height: 224);
      final rng = Random(55);
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final noise = rng.nextInt(10) - 5;
          image.setPixelRgb(
            x, y,
            (45 + noise).clamp(0, 255),
            (55 + noise).clamp(0, 255),
            (120 + noise).clamp(0, 255),
          );
        }
      }
      final bytes = img.encodeJpg(image);
      final result = await EdgeClassifier.analyzeImageBytes(bytes);

      expect(result.isCutaneousTissue, isFalse);
      expect(result.malignantProbability, equals(0.0));
    });

    test('Correctly verifies authentic cutaneous skin lesion', () async {
      final image = img.Image(width: 224, height: 224);
      final rng = Random(42);
      const cy = 112;
      const cx = 112;

      // Realistic skin background with fine biological pores
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final poreNoise = rng.nextInt(16) - 8;
          image.setPixelRgb(
            x,
            y,
            (210 + poreNoise).clamp(0, 255),
            (160 + poreNoise).clamp(0, 255),
            (130 + poreNoise).clamp(0, 255),
          );
        }
      }

      // Add central melanocytic lesion
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final dist = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
          if (dist < 32) {
            final lesionNoise = rng.nextInt(10) - 5;
            image.setPixelRgb(
              x,
              y,
              (65 + lesionNoise).clamp(0, 255),
              (42 + lesionNoise).clamp(0, 255),
              (28 + lesionNoise).clamp(0, 255),
            );
          }
        }
      }

      final bytes = img.encodeJpg(image);
      final result = await EdgeClassifier.analyzeImageBytes(bytes);

      expect(result.isCutaneousTissue, isTrue);
      expect(result.isFocalLesionPresent, isTrue);
      expect(result.skinCoverageRatio, greaterThan(0.60));
      expect(result.focalContrast, greaterThan(0.04));
      expect(result.malignantProbability, greaterThan(0.05));
    });

    test('Correctly accepts human skin under smartphone indoor lighting with zoom', () async {
      final image = img.Image(width: 224, height: 224);
      final rng = Random(101);
      // Realistic indoor lighting arm skin (R=185, G=150, B=135) with dermatoglyphic pore texture
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pore = rng.nextInt(12) - 6;
          image.setPixelRgb(x, y, 185 + pore, 150 + pore, 135 + pore);
        }
      }
      // Add central mole (R=85, G=50, B=35)
      for (int y = 92; y < 132; y++) {
        for (int x = 92; x < 132; x++) {
          final dist = sqrt(pow(x - 112, 2) + pow(y - 112, 2));
          if (dist < 18) {
            image.setPixelRgb(x, y, 85, 50, 35);
          }
        }
      }

      final bytes = img.encodeJpg(image);
      final result = await EdgeClassifier.analyzeImageBytes(bytes, zoomLevel: 1.5);

      expect(result.isCutaneousTissue, isTrue);
      expect(result.isFocalLesionPresent, isTrue);
      expect(result.skinCoverageRatio, greaterThan(0.70));
      expect(result.targetRejectionCategory, equals('NONE'));
    });

    test('Correctly classifies authentic patient melanoma image as High-Risk Melanoma', () async {
      final file = File(r'C:\Users\hameed\.gemini\antigravity\brain\c01032fa-2e78-4056-b4bf-025e6ee06c47\.user_uploaded\media_1794548268653_6b47be14.jpg');
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final result = await EdgeClassifier.analyzeImageBytes(bytes);

        expect(result.isCutaneousTissue, isTrue);
        expect(result.targetRejectionCategory, equals('NONE'));
        expect(result.skinCoverageRatio, greaterThan(0.90));
        expect(result.isFocalLesionPresent, isTrue);
        expect(result.malignantProbability, greaterThan(0.80));
        expect(result.primaryDifferentialDiagnosis, contains('Melanoma'));
        expect(result.icd10Code, contains('C43.9'));
      }
    });

    test('Correctly classifies authentic dataset benign keratosis as Benign (Not Melanoma)', () async {
      final file = File(r'C:\Users\hameed\.gemini\antigravity\brain\c01032fa-2e78-4056-b4bf-025e6ee06c47\.user_uploaded\benign_sample_crop.png');
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final result = await EdgeClassifier.analyzeImageBytes(bytes);

        expect(result.isCutaneousTissue, isTrue);
        expect(result.targetRejectionCategory, equals('NONE'));
        expect(result.skinCoverageRatio, greaterThan(0.80));
        expect(result.isFocalLesionPresent, isTrue);
        // Must NOT be high-risk melanoma! Must be benign (< 0.20 malignant probability)
        expect(result.malignantProbability, lessThan(0.20));
        expect(result.primaryDifferentialDiagnosis, contains('Benign'));
        expect(result.icd10Code, contains('L82.1'));
      }
    });

    // =========================================================================
    // NEW CRITICAL MEDICAL-GRADE DEFENSE TESTS (User Selfie & Quality Guards)
    // =========================================================================
    test('Correctly detects and rejects full-face portrait photograph (User selfie guardrail)', () async {
      final image = img.Image(width: 224, height: 224);
      final rng = Random(123);

      // 1. Skin background (face)
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pore = rng.nextInt(10) - 5;
          image.setPixelRgb(x, y, 205 + pore, 155 + pore, 125 + pore);
        }
      }

      // 2. Top hairline (dark hair)
      for (int y = 0; y < 14; y++) {
        for (int x = 0; x < 224; x++) {
          image.setPixelRgb(x, y, 32, 28, 25);
        }
      }

      // 3. Bottom collar / shirt (dark fabric)
      for (int y = 210; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          image.setPixelRgb(x, y, 40, 45, 60);
        }
      }

      // 4. Left eye & eyebrow (upper-left quadrant)
      for (int y = 50; y < 75; y++) {
        for (int x = 45; x < 85; x++) {
          image.setPixelRgb(x, y, 55, 38, 30);
        }
      }

      // 5. Right eye & eyebrow (upper-right quadrant)
      for (int y = 50; y < 75; y++) {
        for (int x = 139; x < 179; x++) {
          image.setPixelRgb(x, y, 55, 38, 30);
        }
      }

      // 6. Mouth / lips (lower-center)
      for (int y = 145; y < 170; y++) {
        for (int x = 80; x < 144; x++) {
          image.setPixelRgb(x, y, 125, 45, 40);
        }
      }

      final bytes = img.encodeJpg(image);
      final result = await EdgeClassifier.analyzeImageBytes(bytes);

      expect(result.isPreScanPassed, isFalse, reason: 'Full-face portrait must NEVER pass as a solitary skin lesion');
      expect(result.isFaceOrPortrait, isTrue);
      expect(result.targetRejectionCategory, equals('FACIAL_PORTRAIT_DETECTED'));
      expect(result.malignantProbability, equals(0.0), reason: 'Full face must NEVER be assigned a melanoma score');
      expect(result.qualityTitle, contains('Full Face'));
    });

    test('Correctly rejects blurry / out-of-focus image (Blur guardrail)', () async {
      final image = img.Image(width: 224, height: 224);
      // Perfectly smooth gradient without high-frequency edges
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final val = (160 + 20 * sin(x / 40.0) * cos(y / 40.0)).toInt();
          image.setPixelRgb(x, y, val, (val * 0.75).toInt(), (val * 0.60).toInt());
        }
      }

      final bytes = img.encodeJpg(image);
      final result = await EdgeClassifier.analyzeImageBytes(bytes);

      expect(result.isPreScanPassed, isFalse);
      expect(result.isBlurry, isTrue);
      expect(result.targetRejectionCategory, equals('BLURRY_IMAGE'));
      expect(result.malignantProbability, equals(0.0));
      expect(result.qualityTitle, contains('Blurry'));
    });

    test('Correctly rejects camera flash glare / severe overexposure', () async {
      final image = img.Image(width: 224, height: 224);
      // Overexposed white washed out skin
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          image.setPixelRgb(x, y, 252, 248, 240);
        }
      }

      final bytes = img.encodeJpg(image);
      final result = await EdgeClassifier.analyzeImageBytes(bytes);

      expect(result.isPreScanPassed, isFalse);
      expect(result.isGlareOrOverexposed, isTrue);
      expect(result.targetRejectionCategory, equals('OVEREXPOSED_GLARE'));
      expect(result.malignantProbability, equals(0.0));
    });

    test('Correctly rejects dark underexposed image', () async {
      final image = img.Image(width: 224, height: 224);
      // Dark room lighting
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          image.setPixelRgb(x, y, 20, 15, 12);
        }
      }

      final bytes = img.encodeJpg(image);
      final result = await EdgeClassifier.analyzeImageBytes(bytes);

      expect(result.isPreScanPassed, isFalse);
      expect(result.isUnderexposed, isTrue);
      expect(result.targetRejectionCategory, equals('UNDEREXPOSED'));
      expect(result.malignantProbability, equals(0.0));
    });

    test('Correctly rejects uniform normal skin without mole or lesion', () async {
      final image = img.Image(width: 224, height: 224);
      final rng = Random(44);
      // Healthy normal skin with micro-pores but NO mole
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pore = rng.nextInt(8) - 4;
          image.setPixelRgb(x, y, 210 + pore, 160 + pore, 130 + pore);
        }
      }

      final bytes = img.encodeJpg(image);
      final result = await EdgeClassifier.analyzeImageBytes(bytes);

      expect(result.isPreScanPassed, isFalse);
      expect(result.targetRejectionCategory, equals('NO_LESION_FOUND'));
      expect(result.malignantProbability, equals(0.0));
    });
  });
}
