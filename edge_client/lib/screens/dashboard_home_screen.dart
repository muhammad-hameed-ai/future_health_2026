import 'package:flutter/material.dart';
import 'dart:io';
import '../models/saved_scan_record.dart';
import '../services/local_storage_service.dart';
import '../services/pdf_export_service.dart';
import '../services/triage_api_client.dart';

/// Executive UAE Health Dashboard Screen for SkinGuard UAE.
/// Modeled after Apple Health and Babylon Health, showcasing the Future Health Challenge 2026.
class DashboardHomeScreen extends StatefulWidget {
  final VoidCallback onStartNewScan;
  final Function(Map<String, dynamic> sampleData)? onSelectSample;
  final bool isArabic;
  final VoidCallback onToggleLanguage;

  const DashboardHomeScreen({
    super.key,
    required this.onStartNewScan,
    this.onSelectSample,
    this.isArabic = false,
    required this.onToggleLanguage,
  });

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  List<SavedScanRecord> _recentRecords = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final records = await LocalStorageService.getAllRecords();
      if (mounted) {
        setState(() {
          _recentRecords = records;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgSurface = Color(0xFFF8FAFC);
    const brandSky = Color(0xFF0284C7);
    const alertUrgent = Color(0xFFDC2626);
    const alertRoutine = Color(0xFF059669);
    const borderSubtle = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgSurface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHistory,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // 1. Executive Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: alertRoutine,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.isArabic
                                ? 'دائرة الصحة - أبوظبي • تحدي صحة المستقبل'
                                : 'ABU DHABI DOH • FUTURE HEALTH 2026',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: brandSky,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.isArabic ? 'سكين جارد أبوظبي' : 'SkinGuard UAE',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),

                  // Language, Cloud & Privacy Badges
                  Row(
                    children: [
                      // Cloud Hub Badge / Button
                      InkWell(
                        onTap: () => _showCloudSettingsDialog(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBAE6FD)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.cloud_outlined, size: 12, color: brandSky),
                              SizedBox(width: 4),
                              Text(
                                'Cloud Hub',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: brandSky),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Privacy by Design Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 12, color: alertRoutine),
                            SizedBox(width: 4),
                            Text(
                              'Zero-PII',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: alertRoutine),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Language Toggle
                      InkWell(
                        onTap: widget.onToggleLanguage,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderSubtle),
                          ),
                          child: Text(
                            widget.isArabic ? 'English' : 'العربية',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: brandSky),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Hero Action Card (Apple Health Style)
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A0F172A),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.isArabic ? 'فحص سريري فوري' : 'AUTONOMOUS CLINICAL SCREENING',
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const Icon(Icons.verified_outlined, color: Color(0xFF38BDF8), size: 18),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.isArabic
                          ? 'ابدأ الفحص السريري لآفة الجلد'
                          : 'Begin Clinical Skin Lesion Triage',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.isArabic
                          ? 'تحليل ديرموسكوبي متقدم (ABCD + IDS 7-Point) مع توجيه بروتوكول NICE NG12 مباشرة على الجهاز.'
                          : 'Point-of-care dermoscopy analysis (Stolz ABCD + Argenziano 7-Point) with instant NICE NG12 clinical navigation.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFCBD5E1),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandSky,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: widget.onStartNewScan,
                        icon: const Icon(Icons.center_focus_strong_rounded, size: 20),
                        label: Text(
                          widget.isArabic ? 'بدء الفحص السريري الآن' : 'Start Lesion Scan Now',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 3. Active Closed-Loop Care SLA Tracker Card
              InkWell(
                onTap: () => _showClosedLoopDossierModal(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderSubtle),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.sync_alt_rounded, color: brandSky, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                widget.isArabic ? 'متابعة مسار الرعاية المتصلة' : 'CLOSED-LOOP CARE TRACKER',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  'Stage 3/5 Active',
                                  style: TextStyle(color: brandSky, fontSize: 9.5, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios_rounded, size: 9, color: brandSky),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Stepper Progress Row
                      Row(
                        children: [
                          _buildStepIndicator(title: 'Ingested', isDone: true),
                          _buildStepDivider(isDone: true),
                          _buildStepIndicator(title: 'Verified', isDone: true),
                          _buildStepDivider(isDone: true),
                          _buildStepIndicator(title: 'GP Signed', isDone: true, isCurrent: true),
                          _buildStepDivider(isDone: false),
                          _buildStepIndicator(title: 'Handoff', isDone: false),
                          _buildStepDivider(isDone: false),
                          _buildStepIndicator(title: 'Closed', isDone: false),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // SLA Details
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.isArabic ? 'منسقة الرعاية:' : 'Accountable Navigator:',
                                  style: const TextStyle(fontSize: 10.5, color: textSecondary),
                                ),
                                const Text(
                                  'Fatima Al-Mansouri, RN',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.isArabic ? 'المنشأة المعتمدة:' : 'Hospital Referral Partner:',
                                  style: const TextStyle(fontSize: 10.5, color: textSecondary),
                                ),
                                const Text(
                                  'Cleveland Clinic Abu Dhabi (2WW)',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.isArabic ? 'اتفاقية مستوى الخدمة:' : 'Clinical SLA Target:',
                                  style: const TextStyle(fontSize: 10.5, color: textSecondary),
                                ),
                                const Text(
                                  '14-Day Mandatory Biopsy SLA',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: alertUrgent),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            widget.isArabic ? 'اضغط لعرض ملف التدقيق ومحاكاة تنبيه صحتنا' : 'Tap to inspect 5-step journey & simulate Sahatna nudge',
                            style: const TextStyle(fontSize: 10, color: brandSky, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.touch_app_outlined, size: 13, color: brandSky),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // 4. Clinical Benchmark Quick-Scans for Judges
              Text(
                widget.isArabic ? 'عينات الفحص السريري المرجعية' : 'CLINICAL BENCHMARK SAMPLES',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildBenchmarkCard(
                      title: 'Sample A: Suspected Melanoma',
                      titleAr: 'عينة أ: ميلانوما مشتبه بها',
                      badge: 'High Risk (2WW)',
                      badgeColor: alertUrgent,
                      tdsScore: 'TDS: 8.17',
                      diagnosis: 'C43.9 Malignant Melanoma',
                      imageUrl: 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=400&q=80',
                      onTap: () {
                        if (widget.onSelectSample != null) {
                          widget.onSelectSample!({
                            'name': 'Sample A: Suspected Melanoma',
                            'defaultMalignantProb': 0.88,
                            'durationDays': 14,
                            'age': '55-65',
                            'comorbidity': 'Personal History of Melanoma',
                            'asymmetry': 0.82,
                            'border': 0.74,
                            'colorVar': 48.0,
                            'sharpness': 28.5,
                            'diagnosis': 'High-Risk Suspected Cutaneous Melanoma',
                            'icd10': 'C43.9 Malignant Melanoma of Skin, Unspecified',
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildBenchmarkCard(
                      title: 'Sample B: Dysplastic Nevus',
                      titleAr: 'عينة ب: وحمة لانمطية',
                      badge: 'Moderate Risk',
                      badgeColor: const Color(0xFFD97706),
                      tdsScore: 'TDS: 4.85',
                      diagnosis: 'D22.9 Dysplastic Nevus',
                      imageUrl: 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?auto=format&fit=crop&w=400&q=80',
                      onTap: () {
                        if (widget.onSelectSample != null) {
                          widget.onSelectSample!({
                            'name': 'Sample B: Atypical Dysplastic Nevus',
                            'defaultMalignantProb': 0.42,
                            'durationDays': 45,
                            'age': '30-45',
                            'comorbidity': '',
                            'asymmetry': 0.38,
                            'border': 0.45,
                            'colorVar': 28.5,
                            'sharpness': 31.2,
                            'diagnosis': 'Atypical Dysplastic Melanocytic Nevus',
                            'icd10': 'D22.9 Melanocytic Nevus, Unspecified',
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildBenchmarkCard(
                      title: 'Sample C: Benign Keratosis',
                      titleAr: 'عينة ج: تقرن زهمي حميد',
                      badge: 'Low Risk (Benign)',
                      badgeColor: alertRoutine,
                      tdsScore: 'TDS: 2.74',
                      diagnosis: 'L82.1 Seborrheic Keratosis',
                      imageUrl: 'https://images.unsplash.com/photo-1532938911079-1b06ac7ceec7?auto=format&fit=crop&w=400&q=80',
                      onTap: () {
                        if (widget.onSelectSample != null) {
                          widget.onSelectSample!({
                            'name': 'Sample C: Benign Seborrheic Keratosis',
                            'defaultMalignantProb': 0.05,
                            'durationDays': 180,
                            'age': '65+',
                            'comorbidity': 'Type 2 Diabetes',
                            'asymmetry': 0.12,
                            'border': 0.18,
                            'colorVar': 11.2,
                            'sharpness': 26.4,
                            'diagnosis': 'Benign Seborrheic Keratosis (BKL)',
                            'icd10': 'L82.1 Other Seborrheic Keratosis',
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildBenchmarkCard(
                      title: 'Safety Test 1: Motion Blur',
                      titleAr: 'اختبار الأمان 1: تشويش الحركة',
                      badge: 'Gate 1 Optical Guard',
                      badgeColor: const Color(0xFFDC2626),
                      tdsScore: 'Pre-Scan Rejection',
                      diagnosis: 'R68.89 Optical Alert',
                      imageUrl: 'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&w=400&q=80',
                      onTap: () {
                        if (widget.onSelectSample != null) {
                          widget.onSelectSample!({
                            'name': 'Edge Case 1: Motion Blur & Glare Distortion',
                            'defaultMalignantProb': 0.0,
                            'durationDays': 7,
                            'age': '30-45',
                            'comorbidity': '',
                            'asymmetry': 0.0,
                            'border': 0.0,
                            'colorVar': 0.0,
                            'sharpness': 2.1,
                            'diagnosis': 'REJECTED: Motion blur detected. Score: 2.1 < 6.0 threshold. Please steady device and rescan.',
                            'icd10': 'R68.89 Clinical Optical Quality Non-Compliant',
                            'isPreScanFailed': true,
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildBenchmarkCard(
                      title: 'Safety Test 2: Facial Guard',
                      titleAr: 'اختبار الأمان 2: حماية الوجه',
                      badge: 'Gate 4 Facial Triad',
                      badgeColor: const Color(0xFF6B7280),
                      tdsScore: 'Cancer Risk: 0.0%',
                      diagnosis: 'Z00.00 Non-Lesion',
                      imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=400&q=80',
                      onTap: () {
                        if (widget.onSelectSample != null) {
                          widget.onSelectSample!({
                            'name': 'Edge Case 2: Anthropomorphic Face Selfie Rejection',
                            'defaultMalignantProb': 0.0,
                            'durationDays': 3,
                            'age': '18-29',
                            'comorbidity': '',
                            'asymmetry': 0.1,
                            'border': 0.1,
                            'colorVar': 5.0,
                            'sharpness': 28.0,
                            'diagnosis': 'REJECTED: Anthropomorphic facial features detected (eyes/nose/mouth triad). Malignant probability locked to 0.00%.',
                            'icd10': 'Z00.00 Normal Skin (No Neoplastic Lesion)',
                            'isPreScanFailed': true,
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 5. Recent Scan Registry Dossiers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isArabic ? 'سجل الفحوصات الأخيرة' : 'RECENT PATIENT DOSSIERS',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (_recentRecords.isNotEmpty)
                    Text(
                      '${_recentRecords.length} Saved Records',
                      style: const TextStyle(fontSize: 11, color: brandSky, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (_isLoadingHistory)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else if (_recentRecords.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderSubtle),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.folder_open_rounded, size: 36, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 8),
                      Text(
                        widget.isArabic ? 'لا توجد فحوصات سابقة محفوظة' : 'No clinical scans performed yet.',
                        style: const TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isArabic ? 'ابدأ فحصك الأول عبر الزر بالأعلى' : 'Tap the blue button above to perform your first triage scan.',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: _recentRecords.take(4).map((record) => _buildRecentRecordItem(record)).toList(),
                ),
              const SizedBox(height: 20),

              // 6. Abu Dhabi Healthcare Ecosystem Accreditation Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_hospital_rounded, color: Color(0xFF64748B), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.isArabic
                            ? 'نظام سكين جارد متوافق مع شبكة ملفي (Malaffi HIE) ومعايير دائرة الصحة أبوظبي (NICE NG12).'
                            : 'SkinGuard operates in compliance with Malaffi HIE & Abu Dhabi Department of Health clinical standards.',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569), height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator({required String title, required bool isDone, bool isCurrent = false}) {
    return Column(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
            border: isCurrent ? Border.all(color: const Color(0xFF0284C7), width: 3) : null,
          ),
          child: isDone
              ? const Icon(Icons.check, size: 11, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            color: isDone ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider({required bool isDone}) {
    return Expanded(
      child: Container(
        height: 2,
        color: isDone ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
        margin: const EdgeInsets.only(bottom: 14),
      ),
    );
  }

  Widget _buildBenchmarkCard({
    required String title,
    required String titleAr,
    required String badge,
    required Color badgeColor,
    required String tdsScore,
    required String diagnosis,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.network(imageUrl, height: 85, width: 160, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(color: badgeColor, fontSize: 8.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.isArabic ? titleAr : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tdsScore,
                    style: const TextStyle(fontSize: 9.5, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRecordItem(SavedScanRecord record) {
    final isMel = record.primaryDiagnosis.contains('Melanoma');
    final badgeColor = isMel ? const Color(0xFFDC2626) : const Color(0xFF059669);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: record.imagePath != null && File(record.imagePath!).existsSync()
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(record.imagePath!), fit: BoxFit.cover),
                  )
                : const Icon(Icons.image_outlined, color: Color(0xFF94A3B8), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      record.id,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isMel ? '2WW URGENT' : 'BENIGN',
                        style: TextStyle(color: badgeColor, fontSize: 8.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  record.primaryDiagnosis,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.timestamp.day}/${record.timestamp.month}/${record.timestamp.year} • ${record.anatomicalLocation}',
                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF0284C7), size: 20),
            onPressed: () => PdfExportService.exportAndShareRecord(record, context),
          ),
        ],
      ),
    );
  }

  void _showClosedLoopDossierModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => Container(
        height: MediaQuery.of(modalCtx).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 20),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ADPHC SCREENING-TO-CARE LOOP',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF0284C7)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Closed-Loop Governance Dossier',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(modalCtx),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.format_quote_rounded, color: Color(0xFF059669), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '"No actionable results should be left without a clear next step." — Miss Hura Hassan, Head of Screening, ADPHC',
                      style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                children: [
                  // Patient & Registry Header Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('PATIENT / CITIZEN PHR', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            Text('Malaffi HIE: #AE-MAL-7729', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text('Ahmed Al-Hashemi • 58 yrs • Male (Abu Dhabi Resident)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        SizedBox(height: 2),
                        Text('Insurance Network: Thiqa / Daman Enhanced (Cleveland Clinic Abu Dhabi In-Network)', style: TextStyle(fontSize: 10.5, color: Color(0xFF475569))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // The 5-Step Loop Timeline
                  const Text('5-STAGE SCREENING-TO-CARE AUDIT TRAIL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.8)),
                  const SizedBox(height: 10),

                  _buildTimelineItem(
                    stepNum: '1',
                    title: 'Record in Personal Health Record (Malaffi HIE)',
                    status: 'COMPLETED • Nov 12, 09:14 GST',
                    desc: 'Encrypted dermoscopic scan & zero-PII tensor recorded to Malaffi Health Information Exchange.',
                    isDone: true,
                    isCurrent: false,
                  ),
                  _buildTimelineItem(
                    stepNum: '2',
                    title: 'Stratify Risk (NICE NG12 Protocol)',
                    status: 'COMPLETED • Nov 12, 09:15 GST',
                    desc: 'Deterministic Stolz TDS 8.17 (Score > 5.45: High Risk Cutaneous Melanoma). Two-Week Wait (2WW) SLA assigned.',
                    isDone: true,
                    isCurrent: false,
                  ),
                  _buildTimelineItem(
                    stepNum: '3',
                    title: 'Initiate Referral to In-Network Care Partner',
                    status: 'ACTIVE • Hospital Partner Assigned',
                    desc: 'Primary referral dispatched to Cleveland Clinic Abu Dhabi Dermatology Oncology Clinic (SOP-001).',
                    isDone: true,
                    isCurrent: true,
                  ),
                  _buildTimelineItem(
                    stepNum: '4',
                    title: 'Automated Multi-Channel Patient Reminders',
                    status: 'IN PROGRESS • Day 3 of 14 SLA',
                    desc: 'Automated Sahatna push notification & SMS reminders dispatched. Next reminder scheduled in 24 hours.',
                    isDone: false,
                    isCurrent: false,
                  ),
                  _buildTimelineItem(
                    stepNum: '5',
                    title: 'Track Documented Outcome & Audit Sign-Off',
                    status: 'PENDING BIOPSY • Target: Nov 18, 2026',
                    desc: 'Mandatory clinical biopsy confirmation. Case Navigator Fatima Al-Mansouri RN assigned to close loop.',
                    isDone: false,
                    isCurrent: false,
                  ),
                  const SizedBox(height: 16),

                  // Interactive Action 1: Simulate Sahatna Citizen Push Notification
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(modalCtx);
                        _showSahatnaSimulationBanner(context);
                      },
                      icon: const Icon(Icons.notifications_active_rounded, size: 18),
                      label: const Text('Simulate Sahatna Citizen Push Nudge', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Interactive Action 2: Inspect Malaffi FHIR JSON
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        _showMalaffiFhirDialog(context);
                      },
                      icon: const Icon(Icons.code_rounded, size: 18, color: Color(0xFF0284C7)),
                      label: const Text('Inspect Malaffi FHIR Referral JSON', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSahatnaSimulationBanner(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF0284C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_chat_unread_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('صحتنا • SAHATNA HEALTH ALERT', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                      Text('Just now', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9)),
                    ],
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Urgent 2WW Biopsy Appointment scheduled at Cleveland Clinic Abu Dhabi for Nov 18, 2026. Navigator Nurse Fatima is ready to assist.',
                    style: TextStyle(color: Colors.white, fontSize: 11, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMalaffiFhirDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.integration_instructions_rounded, color: Color(0xFF38BDF8), size: 20),
            SizedBox(width: 8),
            Text('Malaffi HIE FHIR Bundle', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 380),
          child: const SingleChildScrollView(
            child: Text(
              '''{
  "resourceType": "Bundle",
  "id": "malaffi-referral-7729",
  "type": "transaction",
  "entry": [
    {
      "resource": {
        "resourceType": "Patient",
        "id": "AE-MAL-7729",
        "identifier": [{"system": "https://malaffi.ae/doh", "value": "784-1968-1234567-1"}],
        "active": true
      }
    },
    {
      "resource": {
        "resourceType": "Observation",
        "code": {"coding": [{"system": "http://snomed.info/sct", "code": "372244006", "display": "Total Dermoscopy Score"}]},
        "valueQuantity": {"value": 8.17, "unit": "TDS"}
      }
    },
    {
      "resource": {
        "resourceType": "ServiceRequest",
        "status": "active",
        "intent": "order",
        "priority": "urgent",
        "code": {"coding": [{"system": "http://snomed.info/sct", "code": "2WW-DERM", "display": "Two-Week Wait Urgent Biopsy"}]},
        "performer": {"display": "Cleveland Clinic Abu Dhabi Dermatology"},
        "note": [{"text": "SOP-001 High Risk Melanoma (ICD-10 C43.9)"}]
      }
    }
  ]
}''',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Color(0xFF38BDF8),
                height: 1.4,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String stepNum,
    required String title,
    required String status,
    required String desc,
    required bool isDone,
    required bool isCurrent,
  }) {
    const brandSky = Color(0xFF0284C7);
    const alertRoutine = Color(0xFF059669);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? alertRoutine : (isCurrent ? brandSky : const Color(0xFFE2E8F0)),
                  border: isCurrent ? Border.all(color: brandSky, width: 2) : null,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : Text(stepNum, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCurrent ? Colors.white : const Color(0xFF64748B))),
                ),
              ),
              Container(width: 2, height: 38, color: const Color(0xFFE2E8F0)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDone ? alertRoutine : (isCurrent ? brandSky : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCloudSettingsDialog(BuildContext context) {
    final controller = TextEditingController(text: TriageApiClient.customServerHost ?? '');
    String? pingStatus;
    bool isPinging = false;
    Color statusColor = const Color(0xFF64748B);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.cloud_sync_rounded, color: Color(0xFF0284C7), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isArabic ? 'إعدادات الخادم السحابي' : 'Cloud Intelligence Gateway',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            widget.isArabic ? 'اتصال سحابي مشفر أو محلي' : 'Remote HTTPS or Local Wi-Fi Hub',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(modalCtx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: Color(0xFF059669)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ZERO-PII CLINICAL ARCHITECTURE: Only anonymized numerical risk tensors are transmitted. Patient photos, names, and identifiers stay 100% on this mobile device. If unreachable, the app operates autonomously offline.',
                        style: TextStyle(fontSize: 10, color: Color(0xFF334155), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cloud Server Base URL:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: 'https://future-health-2026.onrender.com',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.link_rounded, size: 18, color: Color(0xFF0284C7)),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Render (Cloud)', style: TextStyle(fontSize: 10.5)),
                    avatar: const Icon(Icons.cloud_done_rounded, size: 14),
                    onPressed: () {
                      controller.text = 'https://future-health-2026.onrender.com';
                      setModalState(() {});
                    },
                  ),
                  ActionChip(
                    label: const Text('Local Wi-Fi', style: TextStyle(fontSize: 10.5)),
                    avatar: const Icon(Icons.wifi_rounded, size: 14),
                    onPressed: () {
                      controller.text = 'http://192.168.18.14:8000';
                      setModalState(() {});
                    },
                  ),
                  ActionChip(
                    label: const Text('USB Tunnel', style: TextStyle(fontSize: 10.5)),
                    avatar: const Icon(Icons.usb_rounded, size: 14),
                    onPressed: () {
                      controller.text = 'http://127.0.0.1:8000';
                      setModalState(() {});
                    },
                  ),
                ],
              ),
              if (pingStatus != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        statusColor == const Color(0xFF059669)
                            ? Icons.check_circle_rounded
                            : Icons.info_outline_rounded,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pingStatus!,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isPinging
                          ? null
                          : () async {
                              final testTarget = controller.text.trim();
                              if (testTarget.isEmpty) {
                                setModalState(() {
                                  pingStatus = 'Please enter a server URL to test.';
                                  statusColor = const Color(0xFFDC2626);
                                });
                                return;
                              }
                              setModalState(() {
                                isPinging = true;
                                pingStatus = 'Testing connection...';
                                statusColor = const Color(0xFF0284C7);
                              });
                              final ok = await TriageApiClient.pingServer(testTarget);
                              setModalState(() {
                                isPinging = false;
                                if (ok) {
                                  pingStatus = '✓ Connected successfully (HTTP 200 Live)';
                                  statusColor = const Color(0xFF059669);
                                } else {
                                  pingStatus = '⚠️ Unreachable: will use On-Device Autonomous Engine';
                                  statusColor = const Color(0xFFD97706);
                                }
                              });
                            },
                      icon: isPinging
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.network_ping_rounded, size: 16),
                      label: const Text('Test Ping', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final val = controller.text.trim();
                        await LocalStorageService.saveServerHost(val);
                        TriageApiClient.customServerHost = val.isEmpty ? null : val;
                        if (!modalCtx.mounted) return;
                        Navigator.pop(modalCtx);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              val.isEmpty
                                  ? 'Reset to Autonomous On-Device Engine'
                                  : 'Saved Cloud Host: $val',
                            ),
                            backgroundColor: const Color(0xFF0284C7),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.save_rounded, size: 16),
                      label: const Text('Save Host', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
