/// Represents a persistently stored clinical scan record in the local database.
class SavedScanRecord {
  final String id;
  final DateTime timestamp;
  final String? imagePath;
  final double malignantProbability;
  final double benignProbability;
  final String recommendedAction;
  final int timeframeDays;
  final String clinicalRationale;
  final String icd10Code;
  final String primaryDiagnosis;
  final double asymmetryIndex;
  final double borderIrregularity;
  final double colorVariance;
  final double sharpnessScore;
  final Map<String, double> isicProbabilities;
  final String ageBracket;
  final int symptomDays;
  final List<String> comorbidities;
  final bool isConfirmedByClinician;
  final int careLoopStage;
  final String assignedNavigator;
  final String accountableProvider;
  final String slaStatus;
  final String anatomicalLocation;
  final bool isLoopClosed;
  final String? loopClosureNotes;

  SavedScanRecord({
    required this.id,
    required this.timestamp,
    this.imagePath,
    required this.malignantProbability,
    required this.benignProbability,
    required this.recommendedAction,
    required this.timeframeDays,
    required this.clinicalRationale,
    required this.icd10Code,
    required this.primaryDiagnosis,
    required this.asymmetryIndex,
    required this.borderIrregularity,
    required this.colorVariance,
    required this.sharpnessScore,
    required this.isicProbabilities,
    required this.ageBracket,
    required this.symptomDays,
    required this.comorbidities,
    this.isConfirmedByClinician = true,
    this.careLoopStage = 3,
    this.assignedNavigator = 'Fatima Al-Mansouri, RN • Abu Dhabi Tele-Navigation Hub',
    this.accountableProvider = 'SEHA Ambulatory Healthcare Services / Cleveland Clinic AD',
    this.slaStatus = 'On Schedule (14-Day 2WW Target)',
    this.anatomicalLocation = 'Upper Back / Trunk',
    this.isLoopClosed = false,
    this.loopClosureNotes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'imagePath': imagePath,
        'malignantProbability': malignantProbability,
        'benignProbability': benignProbability,
        'recommendedAction': recommendedAction,
        'timeframeDays': timeframeDays,
        'clinicalRationale': clinicalRationale,
        'icd10Code': icd10Code,
        'primaryDiagnosis': primaryDiagnosis,
        'asymmetryIndex': asymmetryIndex,
        'borderIrregularity': borderIrregularity,
        'colorVariance': colorVariance,
        'sharpnessScore': sharpnessScore,
        'isicProbabilities': isicProbabilities,
        'ageBracket': ageBracket,
        'symptomDays': symptomDays,
        'comorbidities': comorbidities,
        'isConfirmedByClinician': isConfirmedByClinician,
        'careLoopStage': careLoopStage,
        'assignedNavigator': assignedNavigator,
        'accountableProvider': accountableProvider,
        'slaStatus': slaStatus,
        'anatomicalLocation': anatomicalLocation,
        'isLoopClosed': isLoopClosed,
        'loopClosureNotes': loopClosureNotes,
      };

  factory SavedScanRecord.fromJson(Map<String, dynamic> json) {
    return SavedScanRecord(
      id: json['id'] as String? ?? 'SG-REF-${DateTime.now().millisecondsSinceEpoch}',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      imagePath: json['imagePath'] as String?,
      malignantProbability: (json['malignantProbability'] as num?)?.toDouble() ?? 0.0,
      benignProbability: (json['benignProbability'] as num?)?.toDouble() ?? 1.0,
      recommendedAction: json['recommendedAction'] as String? ?? 'Primary Care Observation',
      timeframeDays: (json['timeframeDays'] as num?)?.toInt() ?? 21,
      clinicalRationale: json['clinicalRationale'] as String? ?? 'Routine monitoring.',
      icd10Code: json['icd10Code'] as String? ?? 'D22.9',
      primaryDiagnosis: json['primaryDiagnosis'] as String? ?? 'Melanocytic Lesion',
      asymmetryIndex: (json['asymmetryIndex'] as num?)?.toDouble() ?? 0.0,
      borderIrregularity: (json['borderIrregularity'] as num?)?.toDouble() ?? 0.0,
      colorVariance: (json['colorVariance'] as num?)?.toDouble() ?? 0.0,
      sharpnessScore: (json['sharpnessScore'] as num?)?.toDouble() ?? 0.0,
      isicProbabilities: (json['isicProbabilities'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
      ageBracket: json['ageBracket'] as String? ?? '30-45',
      symptomDays: (json['symptomDays'] as num?)?.toInt() ?? 14,
      comorbidities: (json['comorbidities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isConfirmedByClinician: json['isConfirmedByClinician'] as bool? ?? true,
      careLoopStage: (json['careLoopStage'] as num?)?.toInt() ?? 3,
      assignedNavigator: json['assignedNavigator'] as String? ??
          'Fatima Al-Mansouri, RN • Abu Dhabi Tele-Navigation Hub',
      accountableProvider: json['accountableProvider'] as String? ??
          'SEHA Ambulatory Healthcare Services / Cleveland Clinic AD',
      slaStatus: json['slaStatus'] as String? ?? 'On Schedule (14-Day 2WW Target)',
      anatomicalLocation: json['anatomicalLocation'] as String? ?? 'Upper Back / Trunk',
      isLoopClosed: json['isLoopClosed'] as bool? ?? false,
      loopClosureNotes: json['loopClosureNotes'] as String?,
    );
  }
}
