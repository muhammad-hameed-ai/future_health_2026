import 'package:flutter_test/flutter_test.dart';
import 'package:edge_client/services/triage_api_client.dart';

void main() {
  group('TriageApiClient DTO Tests', () {
    test('EdgeRiskVector serializes to zero-PII JSON correctly', () {
      final vector = EdgeRiskVector(
        classProbabilities: [0.10, 0.90],
        inferenceLatencyMs: 28.4,
        domainShiftDetected: false,
      );

      final json = vector.toJson();
      expect(json['class_probabilities'], [0.10, 0.90]);
      expect(json['inference_latency_ms'], 28.4);
      expect(json['domain_shift_detected'], false);
    });

    test('PatientContext serializes to anonymized JSON correctly', () {
      final patient = PatientContext(
        ageBracket: '50-60',
        primarySymptomDurationDays: 21,
        comorbidities: ['hypertension', 'type 2 diabetes'],
      );

      final json = patient.toJson();
      expect(json['age_bracket'], '50-60');
      expect(json['primary_symptom_duration_days'], 21);
      expect(json['comorbidities'], ['hypertension', 'type 2 diabetes']);
    });

    test('TriageResponse deserializes from API JSON correctly', () {
      final json = {
        'recommended_action': 'Urgent Dermatology Referral',
        'timeframe_days': 14,
        'clinical_rationale': 'High risk of cutaneous melanoma.',
        'requires_human_verification': true,
      };

      final response = TriageResponse.fromJson(json);
      expect(response.recommendedAction, 'Urgent Dermatology Referral');
      expect(response.timeframeDays, 14);
      expect(response.clinicalRationale, 'High risk of cutaneous melanoma.');
      expect(response.requiresHumanVerification, true);
    });
  });

  group('TriageApiClient Live Integration Test', () {
    test('getTriagePathway returns grounded pathway from live backend', () async {
      final request = TriageRequest(
        riskVector: EdgeRiskVector(
          classProbabilities: [0.15, 0.85],
          inferenceLatencyMs: 32.1,
          domainShiftDetected: false,
        ),
        patientContext: PatientContext(
          ageBracket: '45-55',
          primarySymptomDurationDays: 14,
          comorbidities: ['hypertension'],
        ),
      );

      final response = await TriageApiClient.getTriagePathway(request);

      expect(response.recommendedAction.isNotEmpty, true);
      expect(response.timeframeDays, greaterThanOrEqualTo(0));
      expect(response.clinicalRationale.isNotEmpty, true);
      expect(response.requiresHumanVerification, true);
    });
  });
}
