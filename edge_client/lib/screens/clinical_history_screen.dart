import 'package:flutter/material.dart';
import '../models/saved_scan_record.dart';
import '../services/local_storage_service.dart';
import '../services/pdf_export_service.dart';
import '../services/language_service.dart';
import '../widgets/region_of_interest_modal.dart';

/// Page 2: Clinical Scan Archive & Local Database.
/// Provides offline longitudinal history, record auditing, care loop closure, and PDF re-export.
class ClinicalHistoryScreen extends StatefulWidget {
  const ClinicalHistoryScreen({super.key});

  @override
  State<ClinicalHistoryScreen> createState() => _ClinicalHistoryScreenState();
}

class _ClinicalHistoryScreenState extends State<ClinicalHistoryScreen> {
  List<SavedScanRecord> _records = [];
  bool _isLoading = true;
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadRecords();
    LocalStorageService.databaseRevisionNotifier.addListener(_onDatabaseChanged);
  }

  void _onDatabaseChanged() {
    if (mounted) {
      _loadRecords();
    }
  }

  @override
  void dispose() {
    LocalStorageService.databaseRevisionNotifier.removeListener(_onDatabaseChanged);
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final list = await LocalStorageService.getAllRecords();
    if (mounted) {
      setState(() {
        _records = list;
        _isLoading = false;
      });
    }
  }

  List<SavedScanRecord> get _filteredRecords {
    if (_selectedFilter == 'URGENT') {
      return _records.where((r) => r.malignantProbability >= 0.60).toList();
    } else if (_selectedFilter == 'ROUTINE') {
      return _records
          .where((r) => r.malignantProbability >= 0.20 && r.malignantProbability < 0.60)
          .toList();
    } else if (_selectedFilter == 'BENIGN') {
      return _records.where((r) => r.malignantProbability < 0.20).toList();
    }
    return _records;
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF8FAFC);
    const textDark = Color(0xFF0F172A);
    const textMuted = Color(0xFF64748B);
    const brandBlue = Color(0xFF0284C7);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CLINICAL ARCHIVE & REGISTRY',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textDark,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              'Zero-PII On-Device Longitudinal Database',
              style: TextStyle(
                fontSize: 11,
                color: textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: brandBlue, size: 20),
            tooltip: 'Reload database records',
            onPressed: _loadRecords,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFDC2626), size: 20),
            tooltip: 'Clear registry',
            onPressed: _confirmClearAll,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: brandBlue))
          : Column(
              children: [
                // Filter Tabs Bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All Scans (${_records.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'URGENT',
                        'Urgent 2WW (${_records.where((r) => r.malignantProbability >= 0.60).length})',
                        color: const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'ROUTINE',
                        'Routine (${_records.where((r) => r.malignantProbability >= 0.20 && r.malignantProbability < 0.60).length})',
                        color: const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'BENIGN',
                        'Benign (${_records.where((r) => r.malignantProbability < 0.20).length})',
                        color: const Color(0xFF059669),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // Record Count & Privacy Note
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: const Color(0xFFF1F5F9),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${_filteredRecords.length} clinical record(s)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 13, color: Color(0xFF059669)),
                          SizedBox(width: 4),
                          Text(
                            'Encrypted Local Storage',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Scan List
                Expanded(
                  child: _filteredRecords.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = _filteredRecords[index];
                            return _buildRecordCard(record);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, {Color? color}) {
    final bool isSelected = _selectedFilter == filterKey;
    final activeColor = color ?? const Color(0xFF0284C7);

    return InkWell(
      onTap: () => setState(() => _selectedFilter = filterKey),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(SavedScanRecord record) {
    final isUrgent = record.malignantProbability >= 0.60;
    final isModerate = record.malignantProbability >= 0.20 && record.malignantProbability < 0.60;

    final badgeColor = isUrgent
        ? const Color(0xFFDC2626)
        : (isModerate ? const Color(0xFFD97706) : const Color(0xFF059669));
    final badgeBg = badgeColor.withOpacity(0.08);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isUrgent ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: ID + Date + Care Loop Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        record.id,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${record.timestamp.day}/${record.timestamp.month}/${record.timestamp.year} ${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: record.isLoopClosed ? const Color(0xFFECFDF5) : badgeBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: record.isLoopClosed ? const Color(0xFF10B981) : badgeColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    record.isLoopClosed
                        ? 'LOOP CLOSED ✅'
                        : (isUrgent ? 'STAGE 4: 2WW ACTIVE' : 'STAGE ${record.careLoopStage}: ACTIVE'),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: record.isLoopClosed ? const Color(0xFF059669) : badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Middle: Risk Dial + Diagnosis + Meta
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: badgeColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${(record.malignantProbability * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.primaryDiagnosis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ICD-10: ${record.icd10Code} • ${record.anatomicalLocation}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Age: ${record.ageBracket} | Target: ${record.timeframeDays} Days | Navigator: Fatima Al-Mansouri',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0284C7),
                      side: const BorderSide(color: Color(0xFFBAE6FD)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.description_outlined, size: 14),
                    label: Text(
                      LanguageService.isArabic ? 'عرض الملف' : 'View Dossier',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => _openRecordDetailModal(record),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
                    label: Text(
                      LanguageService.isArabic ? 'تصدير PDF' : 'Export PDF',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => _exportPdfForRecord(record),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: IconButton(
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(7),
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 18),
                    tooltip: LanguageService.isArabic ? 'حذف التقرير' : 'Delete Report',
                    onPressed: () => _deleteRecordWithUndo(record),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRecordWithUndo(SavedScanRecord record) async {
    final isArabic = LanguageService.isArabic;
    final index = _records.indexOf(record);
    if (index < 0) return;

    // 1. Optimistic removal from UI state
    setState(() {
      _records.removeAt(index);
    });

    // 2. Persist deletion in local storage
    await LocalStorageService.deleteRecord(record.id);

    if (!mounted) return;

    // 3. Show floating confirmation SnackBar with UNDO action for 4 seconds
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isArabic
                    ? 'تم حذف التقرير الطبي ${record.id}'
                    : 'Deleted clinical report ${record.id}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: isArabic ? 'تراجع' : 'UNDO',
          textColor: const Color(0xFF38BDF8),
          onPressed: () async {
            if (!mounted) return;
            setState(() {
              if (index <= _records.length) {
                _records.insert(index, record);
              } else {
                _records.insert(0, record);
              }
            });
            await LocalStorageService.restoreRecord(record, index);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isArabic
                      ? '✓ تمت استعادة التقرير الطبي ${record.id}'
                      : '✓ Restored clinical report ${record.id}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                backgroundColor: const Color(0xFF059669),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openRecordDetailModal(SavedScanRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.id,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'FHIR ServiceRequest (2WW) Dossier • Malaffi Integrated',
                        style: TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFE2E8F0)),
              Expanded(
                child: ListView(
                  children: [
                    // 1. Closed-Loop Care Progression Stepper
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.sync_alt_rounded, color: Color(0xFF0284C7), size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'CARE LOOP LIFECYCLE',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: 0.6),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: record.isLoopClosed ? const Color(0xFFECFDF5) : const Color(0xFFF0F9FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: record.isLoopClosed ? const Color(0xFF10B981) : const Color(0xFF38BDF8)),
                                ),
                                child: Text(
                                  record.isLoopClosed ? 'CLOSED & DOCUMENTED ✅' : 'ACTIVE STAGE ${record.careLoopStage}/5',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: record.isLoopClosed ? const Color(0xFF059669) : const Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _buildHistoryLoopStageChip(1, 'Ingested', record.careLoopStage >= 1),
                              Expanded(child: Container(height: 2, color: record.careLoopStage >= 2 ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0))),
                              _buildHistoryLoopStageChip(2, 'Verified', record.careLoopStage >= 2),
                              Expanded(child: Container(height: 2, color: record.careLoopStage >= 3 ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0))),
                              _buildHistoryLoopStageChip(3, 'Signed', record.careLoopStage >= 3),
                              Expanded(child: Container(height: 2, color: record.careLoopStage >= 4 ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0))),
                              _buildHistoryLoopStageChip(4, 'Dispatched', record.careLoopStage >= 4),
                              Expanded(child: Container(height: 2, color: record.isLoopClosed ? const Color(0xFF059669) : const Color(0xFFE2E8F0))),
                              _buildHistoryLoopStageChip(5, 'Closed', record.isLoopClosed, isFinal: true),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (!record.isLoopClosed)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF059669),
                                  side: const BorderSide(color: Color(0xFFA7F3D0)),
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                icon: const Icon(Icons.check_circle_outline, size: 14),
                                label: const Text('Mark Care Loop Closed (Biopsy Confirmed)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  final updated = SavedScanRecord(
                                    id: record.id,
                                    timestamp: record.timestamp,
                                    imagePath: record.imagePath,
                                    malignantProbability: record.malignantProbability,
                                    benignProbability: record.benignProbability,
                                    recommendedAction: record.recommendedAction,
                                    timeframeDays: record.timeframeDays,
                                    clinicalRationale: record.clinicalRationale,
                                    icd10Code: record.icd10Code,
                                    primaryDiagnosis: record.primaryDiagnosis,
                                    asymmetryIndex: record.asymmetryIndex,
                                    borderIrregularity: record.borderIrregularity,
                                    colorVariance: record.colorVariance,
                                    sharpnessScore: record.sharpnessScore,
                                    isicProbabilities: record.isicProbabilities,
                                    ageBracket: record.ageBracket,
                                    symptomDays: record.symptomDays,
                                    comorbidities: record.comorbidities,
                                    isConfirmedByClinician: true,
                                    careLoopStage: 5,
                                    assignedNavigator: record.assignedNavigator,
                                    accountableProvider: record.accountableProvider,
                                    slaStatus: 'Closed - Biopsy Documented in Malaffi',
                                    anatomicalLocation: record.anatomicalLocation,
                                    isLoopClosed: true,
                                    loopClosureNotes: 'Histopathological verification completed; care loop closed.',
                                  );
                                  await LocalStorageService.saveRecord(updated);
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                  _loadRecords();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Color(0xFF059669),
                                      content: Text('Care Loop Documented: Case closed in local database & Malaffi audit!'),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Accountable Case Ownership Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.badge_outlined, color: Color(0xFF0284C7), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'CASE GOVERNANCE & MALAFFI INTEROPERABILITY',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: 0.6),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow('Assigned Navigator:', record.assignedNavigator),
                          const SizedBox(height: 4),
                          _buildDetailRow('Accountable Facility:', record.accountableProvider),
                          const SizedBox(height: 4),
                          _buildDetailRow('Anatomical Location:', record.anatomicalLocation),
                          const SizedBox(height: 4),
                          _buildDetailRow('SLA Status:', record.slaStatus, isBold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Clinical Determination Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RECOMMENDED CLINICAL PATHWAY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            record.recommendedAction,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            record.clinicalRationale,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF334155),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Stolz ABCD Metrics Table
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EXPLAINABLE STOLZ ABCD METRICS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildMetricRow('Asymmetry Index (A)', '${record.asymmetryIndex.toStringAsFixed(2)} / 1.00'),
                          _buildMetricRow('Border Irregularity (B)', '${record.borderIrregularity.toStringAsFixed(2)} / 1.00'),
                          _buildMetricRow('Color Variegation (C)', record.colorVariance.toStringAsFixed(1)),
                          _buildMetricRow('Optical Sharpness (D)', '${record.sharpnessScore.toStringAsFixed(1)} (Focus verified)'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ISIC 7-Class Distribution
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ISIC 7-CLASS DIFFERENTIAL STRATIFICATION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...record.isicProbabilities.entries.map((entry) {
                            final isMel = entry.key.contains('Melanoma');
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: isMel ? FontWeight.w700 : FontWeight.w500,
                                      color: isMel ? const Color(0xFFDC2626) : const Color(0xFF334155),
                                    ),
                                  ),
                                  Text(
                                    '${(entry.value * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isMel ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bottom Buttons in Modal
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0284C7),
                              side: const BorderSide(color: Color(0xFF0284C7)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.grain_rounded, size: 16),
                            label: const Text('View Heatmap'),
                            onPressed: () {
                              RegionOfInterestModal.show(
                                context,
                                malignantProbability: record.malignantProbability,
                                asymmetryIndex: record.asymmetryIndex,
                                colorVariance: record.colorVariance,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                            label: const Text('Download PDF'),
                            onPressed: () {
                              Navigator.pop(context);
                              _exportPdfForRecord(record);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 135,
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryLoopStageChip(int num, String label, bool isDone, {bool isFinal = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? (isFinal ? const Color(0xFF059669) : const Color(0xFF0284C7))
                : const Color(0xFFF1F5F9),
            border: Border.all(
              color: isDone
                  ? (isFinal ? const Color(0xFF059669) : const Color(0xFF0284C7))
                  : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 11, color: Colors.white)
                : Text('$num', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            color: isDone ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Future<void> _exportPdfForRecord(SavedScanRecord record) async {
    try {
      final file = await PdfExportService.generateAndSaveDossierPdf(record);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Dossier PDF Saved: ${file.path.split('/').last.split('\\').last}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Scan Registry?'),
        content: const Text(
          'This will permanently delete all saved on-device clinical scan records.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(context);
              await LocalStorageService.clearAll();
              _loadRecords();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 54, color: Color(0xFFCBD5E1)),
          SizedBox(height: 12),
          Text(
            'No Clinical Records Found',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          SizedBox(height: 4),
          Text(
            'Perform a scan to save longitudinal records.',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
