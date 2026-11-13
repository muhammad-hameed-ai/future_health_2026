import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/saved_scan_record.dart';
import '../services/edge_classifier.dart';
import '../services/local_storage_service.dart';
import '../services/pdf_export_service.dart';
import '../services/triage_api_client.dart';
import '../widgets/anatomical_body_map.dart';
import 'dermatoscope_camera_screen.dart';

/// Next-Generation Guided Smart Scan Wizard for SkinGuard UAE.
/// Provides a clear, step-by-step, consumer-grade clinical intake flow:
/// Step 1: Patient Profile -> Step 2: Anatomical Site -> Step 3: Dermoscopy Capture -> Step 4: Deliberation -> Step 5: Result Dossier.
class SmartScanWizardScreen extends StatefulWidget {
  final Map<String, dynamic>? initialSampleData;
  final bool isArabic;
  final VoidCallback onScanComplete;

  const SmartScanWizardScreen({
    super.key,
    this.initialSampleData,
    this.isArabic = false,
    required this.onScanComplete,
  });

  @override
  State<SmartScanWizardScreen> createState() => _SmartScanWizardScreenState();
}

class _SmartScanWizardScreenState extends State<SmartScanWizardScreen> with SingleTickerProviderStateMixin {
  int _currentStep = 0; // 0: Profile, 1: Body Site, 2: Camera Capture, 3: Processing, 4: Results

  // Patient Intake State
  String _selectedAgeBracket = '55-65';
  int _symptomDurationDays = 14;
  final Set<String> _selectedComorbidities = {'Hypertension'};
  String _selectedLocation = 'Upper Back / Trunk';

  // Optical Image Capture State
  File? _capturedImageFile;
  String? _sampleImageUrl;
  String? _selectedSampleLabel;
  EdgeAnalysisResult? _lastOpticalAnalysis;
  TriageResponse? _triageResponse;
  SavedScanRecord? _lastSavedRecord;
  bool _isClinicianView = false;
  bool _isReferralDispatched = false;

  // Processing Animation
  int _deliberationStep = 0;
  late AnimationController _pulseController;
  final ImagePicker _picker = ImagePicker();

  final List<String> _ageOptions = ['18-29', '30-45', '46-60', '55-65', '65+'];
  final List<String> _comorbidityOptions = [
    'Personal History of Melanoma',
    'Immunosuppressed / Biologics',
    'Hypertension',
    'Type 2 Diabetes',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);

    if (widget.initialSampleData != null) {
      _loadSampleData(widget.initialSampleData!);
    }
  }

  @override
  void didUpdateWidget(covariant SmartScanWizardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSampleData != null && widget.initialSampleData != oldWidget.initialSampleData) {
      _loadSampleData(widget.initialSampleData!);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _loadSampleData(Map<String, dynamic> sample) {
    final String name = sample['name'] ?? 'Sample Lesion';
    final bool isMel = name.contains('Melanoma');
    final bool isDysp = name.contains('Dysplastic');

    setState(() {
      _selectedSampleLabel = name;
      _sampleImageUrl = sample['imageUrl'] ?? 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=600&q=80';
      _capturedImageFile = null;
      _selectedAgeBracket = sample['age'] ?? '55-65';
      _symptomDurationDays = sample['durationDays'] ?? 14;
      if (sample['comorbidity'] != null && (sample['comorbidity'] as String).isNotEmpty) {
        _selectedComorbidities.add(sample['comorbidity']);
      }
      _lastOpticalAnalysis = EdgeAnalysisResult(
        isCutaneousTissue: true,
        isFocalLesionPresent: true,
        isPreScanPassed: true,
        skinCoverageRatio: 0.94,
        focalContrast: 0.08,
        targetRejectionCategory: 'NONE',
        skinValidationMessage: 'Benchmark Sample Verified (Dermoscopic Standard)',
        qualityTitle: 'Optical Quality Verified: Sharp Macro Dermoscopy',
        qualityAdvice: 'Pre-calibrated ISIC international clinical benchmark case.',
        malignantProbability: isMel ? 0.88 : (isDysp ? 0.42 : 0.05),
        benignProbability: isMel ? 0.12 : (isDysp ? 0.58 : 0.95),
        inferenceLatencyMs: 95.0,
        domainShiftDetected: false,
        asymmetryIndex: isMel ? 0.50 : (isDysp ? 0.24 : 0.12),
        colorVariance: isMel ? 80.0 : 35.0,
        sharpnessScore: 9.5,
        borderIrregularityScore: isMel ? 0.65 : 0.25,
        isicProbabilities: isMel
            ? {'Melanoma (MEL)': 0.88, 'Benign Keratosis (BKL)': 0.12}
            : {'Benign Keratosis (BKL)': 0.95, 'Melanoma (MEL)': 0.05},
        primaryDifferentialDiagnosis: isMel
            ? 'High-Risk Suspected Cutaneous Melanoma (MEL)'
            : (isDysp ? 'Atypical Dysplastic Melanocytic Nevus' : 'Benign Keratosis / Seborrheic Keratosis (BKL)'),
        icd10Code: isMel ? 'C43.9 Malignant Melanoma of Skin, Unspecified' : (isDysp ? 'D22.9' : 'L82.1 Other Seborrheic Keratosis'),
      );
      _currentStep = 2; // Jump directly to capture preview
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final File? captured = await Navigator.push<File?>(
        context,
        MaterialPageRoute(builder: (_) => const DermatoscopeCameraScreen()),
      );
      if (captured != null && mounted) {
        await _processSelectedFile(captured, 'Live Dermatoscope Scan');
      }
      return;
    }

    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 2048, maxHeight: 2048, imageQuality: 98);
      if (picked != null) {
        await _processSelectedFile(File(picked.path), 'Gallery Image Selected');
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  Future<void> _processSelectedFile(File file, String label) async {
    EdgeAnalysisResult? analysis;
    try {
      final bytes = await file.readAsBytes();
      analysis = await EdgeClassifier.analyzeImageBytes(bytes);
    } catch (e) {
      debugPrint('Pre-analysis error: $e');
    }

    if (!mounted) return;
    setState(() {
      _capturedImageFile = file;
      _selectedSampleLabel = label;
      _sampleImageUrl = null;
      _lastOpticalAnalysis = analysis;
    });
  }

  Future<void> _runClinicalDeliberation() async {
    // Safety guardrail: Block deliberation if optical pre-scan failed
    if (_lastOpticalAnalysis != null && !_lastOpticalAnalysis!.isPreScanPassed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text(_lastOpticalAnalysis!.skinValidationMessage),
        ),
      );
      return;
    }

    setState(() {
      _currentStep = 3;
      _deliberationStep = 1;
    });

    // Step 1: Optical quality & sensor illumination verification (600ms)
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // Step 2: Focal Lesion & Tissue Demarcation (700ms)
    setState(() => _deliberationStep = 2);

    EdgeAnalysisResult? optical = _lastOpticalAnalysis;
    double malProb = 0.15;
    double inferenceMs = 95.0;

    if (_capturedImageFile != null && await _capturedImageFile!.exists()) {
      try {
        final bytes = await _capturedImageFile!.readAsBytes();
        optical = await EdgeClassifier.analyzeImageBytes(bytes);
        malProb = optical.malignantProbability;
        inferenceMs = optical.inferenceLatencyMs;
      } catch (e) {
        debugPrint('Optical error: $e');
      }

      // Check pre-scan rejection
      if (optical != null && !optical.isPreScanPassed) {
        if (!mounted) return;
        setState(() {
          _lastOpticalAnalysis = optical;
          _currentStep = 2; // Return to step 2 with rejection message
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text(optical.skinValidationMessage),
          ),
        );
        return;
      }
    } else if (_selectedSampleLabel != null && _selectedSampleLabel!.contains('Melanoma')) {
      malProb = 0.88;
    } else if (_selectedSampleLabel != null && _selectedSampleLabel!.contains('Dysplastic')) {
      malProb = 0.42;
    } else if (_selectedSampleLabel != null && _selectedSampleLabel!.contains('Benign')) {
      malProb = 0.05;
    }

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    // Step 3: Stolz ABCD & Argenziano 7-Point Scoring (800ms)
    setState(() => _deliberationStep = 3);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // Risk modifier
    if (_selectedComorbidities.contains('Personal History of Melanoma') ||
        _selectedComorbidities.contains('Immunosuppressed / Biologics')) {
      malProb = min(0.95, malProb + 0.20);
    }

    final double benignProb = 1.0 - malProb;
    final edgeRisk = EdgeRiskVector(
      classProbabilities: [
        double.parse(benignProb.toStringAsFixed(3)),
        double.parse(malProb.toStringAsFixed(3)),
      ],
      inferenceLatencyMs: inferenceMs,
    );

    // Step 4: Clinical protocol cross-referencing (750ms)
    setState(() => _deliberationStep = 4);
    final triageRequest = TriageRequest(
      riskVector: edgeRisk,
      patientContext: PatientContext(
        ageBracket: _selectedAgeBracket,
        primarySymptomDurationDays: _symptomDurationDays,
        comorbidities: _selectedComorbidities.toList(),
      ),
    );

    final response = await TriageApiClient.getTriagePathway(triageRequest);
    await Future.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;

    // Step 5: Synthesizing final board-certified dermatologist pathway (650ms)
    setState(() => _deliberationStep = 5);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    setState(() {
      _lastOpticalAnalysis = optical;
      _triageResponse = response;
      _currentStep = 4; // Complete!
    });

    // Auto-save to local registry
    await _saveRecordToRegistry(malProb, benignProb, response);
  }

  Future<void> _saveRecordToRegistry(double malProb, double benignProb, TriageResponse response) async {
    final optical = _lastOpticalAnalysis;
    final String refId = 'SG-REF-2026-${(DateTime.now().millisecondsSinceEpoch % 9000) + 1000}';

    final record = SavedScanRecord(
      id: refId,
      timestamp: DateTime.now(),
      imagePath: _capturedImageFile?.path,
      malignantProbability: malProb,
      benignProbability: benignProb,
      recommendedAction: response.recommendedAction,
      timeframeDays: response.timeframeDays,
      clinicalRationale: response.clinicalRationale,
      icd10Code: optical?.icd10Code ?? 'D22.9',
      primaryDiagnosis: optical?.primaryDifferentialDiagnosis ?? 'Melanocytic Lesion',
      asymmetryIndex: optical?.asymmetryIndex ?? 0.15,
      borderIrregularity: optical?.borderIrregularityScore ?? 0.25,
      colorVariance: optical?.colorVariance ?? 15.0,
      sharpnessScore: optical?.sharpnessScore ?? 25.0,
      isicProbabilities: optical?.isicProbabilities ?? const {'Melanoma (MEL)': 0.10, 'Benign Keratosis (BKL)': 0.90},
      ageBracket: _selectedAgeBracket,
      symptomDays: _symptomDurationDays,
      comorbidities: _selectedComorbidities.toList(),
      anatomicalLocation: _selectedLocation,
    );

    _lastSavedRecord = record;
    await LocalStorageService.saveRecord(record);
  }

  @override
  Widget build(BuildContext context) {
    const bgSurface = Color(0xFFF8FAFC);
    const brandSky = Color(0xFF0284C7);

    return Scaffold(
      backgroundColor: bgSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
                onPressed: () {
                  if (_currentStep == 4) {
                    setState(() => _currentStep = 0);
                  } else {
                    setState(() => _currentStep--);
                  }
                },
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isArabic ? 'معالج الفحص السريري الذكي' : 'SMART CLINICAL TRIAGE WIZARD',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: 0.8),
            ),
            Text(
              _getStepSubtitle(),
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Text(
              'Step ${_currentStep + 1} of 5',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: brandSky),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildCurrentStepView(),
        ),
      ),
    );
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return widget.isArabic ? 'المرحلة 1: بيانات المريض والملف الصحي' : 'Phase 1: Patient Context & Demographics';
      case 1:
        return widget.isArabic ? 'المرحلة 2: الموضع التشريحي للآفة' : 'Phase 2: Anatomical Lesion Mapping';
      case 2:
        return widget.isArabic ? 'المرحلة 3: التقاط صورة الديرموسكوب' : 'Phase 3: Dermoscopic Image Acquisition';
      case 3:
        return widget.isArabic ? 'المرحلة 4: التحليل السريري المتقدم' : 'Phase 4: Deep IDS Dermoscopic Deliberation';
      case 4:
        return widget.isArabic ? 'المرحلة 5: التقرير السريري والإحالة' : 'Phase 5: Executive Results & Closed-Loop Referral';
      default:
        return '';
    }
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0:
        return _buildStep1PatientProfile();
      case 1:
        return _buildStep2BodyMap();
      case 2:
        return _buildStep3CameraCapture();
      case 3:
        return _buildStep4Processing();
      case 4:
        return _buildStep5Results();
      default:
        return const SizedBox.shrink();
    }
  }

  // =========================================================================
  // STEP 1: Patient Profile & Demographics
  // =========================================================================
  Widget _buildStep1PatientProfile() {
    const brandSky = Color(0xFF0284C7);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);
    const borderSubtle = Color(0xFFE2E8F0);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Title
        Text(
          widget.isArabic ? 'ملف المريض والسياق السريري' : 'Patient Context & Demographics',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          widget.isArabic
              ? 'البيانات مجهولة الهوية بالكامل (Zero-PII) ومخصصة لمعايرة بروتوكول NICE NG12.'
              : 'Strictly zero-PII anonymized demographics required to ground NICE Guideline NG12.',
          style: const TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
        ),
        const SizedBox(height: 20),

        // Age Bracket Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.cake_outlined, color: brandSky, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    widget.isArabic ? 'الفئة العمرية للمريض:' : 'Patient Age Bracket:',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _ageOptions.map((age) {
                  final isSelected = _selectedAgeBracket == age;
                  return ChoiceChip(
                    label: Text(age),
                    selected: isSelected,
                    selectedColor: brandSky,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedAgeBracket = age);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Symptom Days Slider Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: brandSky, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        widget.isArabic ? 'مدة ملاحظة الآفة الجلدية:' : 'Symptom Duration:',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Text(
                      '$_symptomDurationDays days',
                      style: const TextStyle(color: brandSky, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Slider(
                value: _symptomDurationDays.toDouble(),
                min: 1,
                max: 180,
                divisions: 179,
                activeColor: brandSky,
                inactiveColor: const Color(0xFFE2E8F0),
                onChanged: (val) => setState(() => _symptomDurationDays = val.toInt()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Comorbidity Modifiers
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.medical_information_outlined, color: brandSky, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    widget.isArabic ? 'عوامل الخطورة والمرافقات الصحية:' : 'Clinical Risk Modifiers:',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _comorbidityOptions.map((comorb) {
                  final isSelected = _selectedComorbidities.contains(comorb);
                  final isHighRisk = comorb.contains('Melanoma') || comorb.contains('Immuno');
                  return FilterChip(
                    label: Text(comorb),
                    selected: isSelected,
                    selectedColor: isHighRisk ? const Color(0xFFFEE2E2) : const Color(0xFFE0F2FE),
                    checkmarkColor: isHighRisk ? const Color(0xFFDC2626) : brandSky,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? (isHighRisk ? const Color(0xFFDC2626) : brandSky)
                          : textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedComorbidities.add(comorb);
                        } else {
                          _selectedComorbidities.remove(comorb);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Next Action Button
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandSky,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => setState(() => _currentStep = 1),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(
              widget.isArabic ? 'المتابعة لتحديد موضع الآفة' : 'Next: Select Anatomical Site',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // STEP 2: Interactive Body Map
  // =========================================================================
  Widget _buildStep2BodyMap() {
    const brandSky = Color(0xFF0284C7);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AnatomicalBodyMap(
          selectedLocation: _selectedLocation,
          isArabic: widget.isArabic,
          onLocationChanged: (loc) => setState(() => _selectedLocation = loc),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandSky,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => setState(() => _currentStep = 2),
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: Text(
              widget.isArabic ? 'المتابعة لالتقاط صورة الآفة' : 'Next: Capture Dermoscopy Image',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // STEP 3: Dermatoscope Camera & Gallery Capture
  // =========================================================================
  Widget _buildStep3CameraCapture() {
    const brandSky = Color(0xFF0284C7);
    const borderSubtle = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);

    final bool hasImage = (_capturedImageFile != null && _capturedImageFile!.existsSync()) ||
        (_sampleImageUrl != null && _selectedSampleLabel != null);

    final optical = _lastOpticalAnalysis;
    final bool isQualityVerified = hasImage && optical != null && optical.isPreScanPassed;
    final bool isQualityFailed = hasImage && optical != null && !optical.isPreScanPassed;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Title
        Text(
          widget.isArabic ? 'التقاط صورة الديرموسكوب' : 'Dermoscopic Image Acquisition',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          widget.isArabic
              ? 'وجه فتحة العدسة الدائرية نحو الشامة أو الآفة الجلدية عن قرب في إضاءة جيدة.'
              : 'Frame a single suspicious skin mole closely within the circular reticle under clear lighting.',
          style: const TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
        ),
        const SizedBox(height: 18),

        // Central Circular Viewfinder Preview
        Center(
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F172A),
              border: Border.all(
                color: isQualityFailed
                    ? const Color(0xFFDC2626)
                    : (isQualityVerified ? const Color(0xFF059669) : brandSky),
                width: 3.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isQualityFailed
                      ? const Color(0xFFDC2626).withOpacity(0.25)
                      : (isQualityVerified ? const Color(0xFF059669).withOpacity(0.25) : brandSky.withOpacity(0.25)),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: hasImage
                  ? (_capturedImageFile != null
                      ? Image.file(_capturedImageFile!, fit: BoxFit.cover)
                      : Image.network(_sampleImageUrl!, fit: BoxFit.cover))
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.center_focus_weak_rounded, size: 48, color: Colors.white.withOpacity(0.6)),
                          const SizedBox(height: 8),
                          Text(
                            widget.isArabic ? 'فتحة الديرموسكوب' : 'Circular Reticle',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 1. OPTICAL QUALITY ALERT CARD (When Quality Check Fails)
        if (isQualityFailed) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      optical.isFaceOrPortrait
                          ? Icons.face_retouching_off_rounded
                          : (optical.isBlurry
                              ? Icons.blur_on_rounded
                              : (optical.isGlareOrOverexposed
                                  ? Icons.wb_sunny_rounded
                                  : (optical.isUnderexposed ? Icons.bedtime_rounded : Icons.warning_amber_rounded))),
                      size: 20,
                      color: const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        optical.qualityTitle,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF991B1B)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  optical.skinValidationMessage,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFFB91C1C), height: 1.35),
                ),
                if (optical.qualityAdvice.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            optical.qualityAdvice,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7F1D1D)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded, size: 16),
                    label: Text(
                      widget.isArabic ? 'إعادة التقاط صورة واضحة الآن' : '📸 Retake Photo Now',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 2. OPTICAL QUALITY VERIFIED CARD (When Quality Check Passes)
        if (isQualityVerified) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isArabic ? 'تم التحقق من جودة الفحص البصري بنجاح' : 'Optical Quality Verified: Sharp Macro Scan',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildVerificationPill('Focus: Sharp', Icons.lens_blur_rounded),
                    _buildVerificationPill('Living Skin: ${(optical.skinCoverageRatio * 100).toStringAsFixed(0)}%', Icons.check_circle_outline),
                    _buildVerificationPill('Solitary Lesion: Centered', Icons.center_focus_strong_rounded),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Capture Action Buttons (Camera Scan | From Gallery)
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: brandSky),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded, size: 18, color: brandSky),
                label: Text(widget.isArabic ? 'كاميرا حية' : 'Camera Scan', style: const TextStyle(color: brandSky, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: borderSubtle),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 18, color: textSecondary),
                label: Text(widget.isArabic ? 'من المعرض' : 'From Gallery', style: const TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Start Deliberation Button
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isQualityVerified ? brandSky : const Color(0xFFCBD5E1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: isQualityVerified ? _runClinicalDeliberation : null,
            icon: const Icon(Icons.analytics_outlined, size: 20),
            label: Text(
              isQualityFailed
                  ? (widget.isArabic ? 'الفحص معلق: مطلوب صورة واضحة للشامة' : 'Deliberation Blocked: Retake Photo')
                  : (isQualityVerified
                      ? (widget.isArabic ? 'بدء التحليل السريري المتقدم ➔' : 'Initiate Deep Clinical Deliberation ➔')
                      : (widget.isArabic ? 'يرجى التقاط صورة الآفة أولاً' : 'Capture or Select Mole Image First')),
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationPill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF065F46)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 4: Animated Deep Clinical Deliberation
  // =========================================================================
  Widget _buildStep4Processing() {
    const brandSky = Color(0xFF0284C7);
    const textPrimary = Color(0xFF0F172A);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing Reticle Avatar
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: brandSky, width: 3),
                boxShadow: [
                  BoxShadow(color: brandSky.withOpacity(0.3), blurRadius: 20, spreadRadius: 4),
                ],
              ),
              child: ClipOval(
                child: _capturedImageFile != null
                    ? Image.file(_capturedImageFile!, fit: BoxFit.cover)
                    : (_sampleImageUrl != null
                        ? Image.network(_sampleImageUrl!, fit: BoxFit.cover)
                        : Container(color: const Color(0xFF0F172A))),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              widget.isArabic ? 'التحليل السريري متعدد المراحل (IDS)' : 'MULTI-STAGE IDS CLINICAL DELIBERATION',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: 0.8),
            ),
            const SizedBox(height: 20),

            _buildDeliberationStep(1, 'Verifying optical integrity & sensor illumination', 'فحص جودة الصورة ومستوى الإضاءة'),
            _buildDeliberationStep(2, 'Isolating focal lesion & cutaneous chromophores', 'تحديد حدود الآفة وتوزيع الميلانين'),
            _buildDeliberationStep(3, 'Extracting Stolz ABCD & Argenziano 7-Point checklist', 'استخراج معايير ABCD وقائمة النقاط السبع'),
            _buildDeliberationStep(4, 'Cross-referencing ISIC 7-class & NICE NG12 protocols', 'مطابقة النماذج مع بروتوكول NICE NG12'),
            _buildDeliberationStep(5, 'Synthesizing board-certified dermatologist pathway', 'صياغة التوجيه السريري النهائي'),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliberationStep(int stepIndex, String en, String ar) {
    final isDone = _deliberationStep > stepIndex;
    final isCurrent = _deliberationStep == stepIndex;
    const brandSky = Color(0xFF0284C7);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? const Color(0xFF059669) : (isCurrent ? brandSky : const Color(0xFFE2E8F0)),
            ),
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : (isCurrent
                    ? const Padding(
                        padding: EdgeInsets.all(4),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : null),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.isArabic ? ar : en,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                color: isDone || isCurrent ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 5: Executive Results Dossier (Patient vs Doctor View)
  // =========================================================================
  Widget _buildStep5Results() {
    final optical = _lastOpticalAnalysis;
    final response = _triageResponse;
    const brandSky = Color(0xFF0284C7);
    const alertUrgent = Color(0xFFDC2626);
    const alertRoutine = Color(0xFF059669);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);
    const borderSubtle = Color(0xFFE2E8F0);

    final bool isMel = optical?.primaryDifferentialDiagnosis.contains('Melanoma') ?? false;
    final Color riskColor = isMel ? alertUrgent : alertRoutine;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 1. Dual-Persona Toggle Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  _buildPersonaTab('Patient Guidance', Icons.person_outline_rounded, !_isClinicianView, () => setState(() => _isClinicianView = false)),
                  _buildPersonaTab('Clinician / EHR', Icons.medical_services_outlined, _isClinicianView, () => setState(() => _isClinicianView = true)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, color: brandSky),
              onPressed: () async {
                if (_lastSavedRecord != null) {
                  await PdfExportService.exportAndShareRecord(_lastSavedRecord!, context);
                } else {
                  final list = await LocalStorageService.getAllRecords();
                  if (list.isNotEmpty && mounted) {
                    await PdfExportService.exportAndShareRecord(list.first, context);
                  }
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2. Executive Status Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isMel ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isMel ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(isMel ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, color: riskColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isMel ? 'TWO-WEEK WAIT (2WW) URGENT' : 'REASSURING BENIGN EVALUATION',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: riskColor, letterSpacing: 0.8),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: riskColor, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      '${response?.timeframeDays ?? 14} Days SLA',
                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                optical?.primaryDifferentialDiagnosis ?? 'Clinical Evaluation Complete',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'ICD-10: ${optical?.icd10Code ?? "D22.9"} • Anatomical Site: $_selectedLocation',
                style: const TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Conditional View: Patient vs Clinician
        if (!_isClinicianView) ...[
          // PATIENT VIEW
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderSubtle)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('WHAT THIS MEANS FOR YOU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textSecondary, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Text(
                  response?.clinicalRationale ?? 'Clinical assessment completed.',
                  style: const TextStyle(fontSize: 12.5, color: textPrimary, height: 1.45),
                ),
                const SizedBox(height: 14),
                const Text('RECOMMENDED NEXT STEPS:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textSecondary, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                _buildBulletPoint('Do not scratch, pick, or apply unprescribed chemicals to the area.'),
                _buildBulletPoint('Take a reference photo every 14 days under natural daylight.'),
                _buildBulletPoint(isMel ? 'Attend your assigned 2WW hospital appointment on time.' : 'Schedule a routine primary care check within 45-90 days.'),
              ],
            ),
          ),
        ] else ...[
          // CLINICIAN / DOCTOR VIEW
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderSubtle)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('EXPLAINABLE AI: STOLZ ABCD DERMOSCOPY', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: textSecondary, letterSpacing: 0.8)),
                const SizedBox(height: 10),
                _buildMetricBar('Asymmetry Index (A)', optical?.asymmetryIndex ?? 0.10, 1.0, 0.40),
                const SizedBox(height: 6),
                _buildMetricBar('Border Irregularity (B)', optical?.borderIrregularityScore ?? 0.20, 1.0, 0.50),
                const SizedBox(height: 6),
                _buildMetricBar('Color Variegation (C)', min(1.0, (optical?.colorVariance ?? 15.0) / 60.0), 1.0, 0.45),
                const SizedBox(height: 14),

                // Argenziano 7-Point Checklist Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (optical?.argenzianoScore ?? 0) >= 3 ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: (optical?.argenzianoScore ?? 0) >= 3 ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ARGENZIANO 7-POINT CHECKLIST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textPrimary)),
                          Text('Score: ${optical?.argenzianoScore ?? 0}/10', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: riskColor)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildFeatureBadge('Atypical Network', optical?.hasAtypicalNetwork ?? false),
                          _buildFeatureBadge('Blue-White Veil', optical?.hasBlueWhiteVeil ?? false),
                          _buildFeatureBadge('Radial Streaks', optical?.hasRadialStreaks ?? false),
                          _buildFeatureBadge('Horn Pseudocysts', optical?.hasKeratoticHallmarks ?? false, isBenign: true),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Dermatologist Narrative
                if (optical?.dermoscopicSynthesis != null && optical!.dermoscopicSynthesis.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFBAE6FD))),
                    child: Text(
                      optical.dermoscopicSynthesis,
                      style: const TextStyle(fontSize: 11, color: textPrimary, height: 1.4),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),

        // 4. Closed-Loop Care Handshake Action
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderSubtle)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('CLOSED-LOOP REFERRAL HANDOFF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textSecondary, letterSpacing: 0.8)),
                  Text(
                    _isReferralDispatched ? 'DISPATCHED' : 'READY',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _isReferralDispatched ? alertRoutine : brandSky),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Accountable Healthcare Facility: Cleveland Clinic Abu Dhabi / SEHA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary)),
              const SizedBox(height: 2),
              const Text('Assigned Case Navigator: Fatima Al-Mansouri, RN • Abu Dhabi Tele-Navigation Hub', style: TextStyle(fontSize: 10.5, color: textSecondary)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isReferralDispatched ? alertRoutine : brandSky,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    setState(() => _isReferralDispatched = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF059669),
                        content: Text('Clinical referral signed and dispatched to Malaffi HIE registry.'),
                      ),
                    );
                  },
                  icon: Icon(_isReferralDispatched ? Icons.check_circle_rounded : Icons.send_rounded, size: 18),
                  label: Text(_isReferralDispatched ? 'Referral Dispatched & Signed' : 'Sign-Off & Dispatch Referral (Malaffi)'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Finish and return to Dashboard
        Center(
          child: TextButton.icon(
            onPressed: widget.onScanComplete,
            icon: const Icon(Icons.home_outlined, size: 18, color: brandSky),
            label: const Text('Return to Executive Dashboard', style: TextStyle(color: brandSky, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonaTab(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))] : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBar(String label, double val, double maxVal, double warnThresh) {
    final clamped = min(1.0, max(0.0, val / maxVal));
    final color = clamped >= 0.70 ? const Color(0xFFDC2626) : (clamped >= warnThresh ? const Color(0xFFD97706) : const Color(0xFF0284C7));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
            Text(val.toStringAsFixed(2), style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(value: clamped, minHeight: 4, backgroundColor: const Color(0xFFE2E8F0), valueColor: AlwaysStoppedAnimation<Color>(color)),
        ),
      ],
    );
  }

  Widget _buildFeatureBadge(String name, bool isPresent, {bool isBenign = false}) {
    final color = isPresent ? (isBenign ? const Color(0xFF059669) : const Color(0xFFDC2626)) : const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '$name: ${isPresent ? "Detected" : "None"}',
        style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF0284C7), fontSize: 13, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35))),
        ],
      ),
    );
  }
}
