import 'dart:math' as math;

import '../models/hyope_models.dart';

// -----------------------------------------------------------------------------
// Mock Data: 백엔드 연결 전 화면 확인용
// -----------------------------------------------------------------------------

class MockData {
  static const recipient = RecipientSummary(
    id: 1,
    name: 'OOO',
    relation: '부모님',
    phoneNumber: '010-1234-5678',
  );

  static List<DailyAssessment> last30Days() {
    final today = DateTime.now();
    final List<DailyAssessment> result = [];

    for (int i = 0; i < 30; i++) {
      final date = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 29 - i));

      final wave = math.sin(i / 3.2) * 0.9;
      final healthRisk = (2.2 + wave + (i % 9 == 0 ? 1.2 : 0.0))
          .clamp(0.0, 10.0)
          .toDouble();
      final emotional = (6.6 - wave + (i % 10 == 3 ? -1.5 : 0.0))
          .clamp(0.0, 10.0)
          .toDouble();
      final depression = (10 - emotional + 0.7).clamp(0.0, 10.0).toDouble();
      final cognitive = (7.0 + math.cos(i / 4.0) * 0.7).clamp(0.0, 10.0).toDouble();
      final missedPenalty = (i % 7 == 0 ? 1.0 : 0.0) + (i % 11 == 0 ? 1.3 : 0.0);
      final overallRisk = (healthRisk * 0.45 + depression * 0.25 + missedPenalty + 1.0)
          .clamp(0.0, 10.0)
          .toDouble();
      final risk = riskLevelFromScore(overallRisk);

      result.add(
        DailyAssessment(
          id: i + 1,
          recipientId: 1,
          callLogId: i + 1,
          measuredAt: DateTime(date.year, date.month, date.day, 7, 4),
          depressionScore: depression,
          emotionalStability: emotional,
          healthRisk: healthRisk,
          cognitiveScore: cognitive,
          overallRisk: overallRisk,
          riskLevel: risk,
          recommendation: risk.actionDescription,
          adherenceRecords: _adherenceRecords(i + 1, i),
        ),
      );
    }
    return result;
  }

  static List<AdherenceRecord> _adherenceRecords(int assessmentId, int index) {
    final mealMiss = index % 7 == 0;
    final medMiss = index % 11 == 0;
    final unknownDinner = index % 13 == 0;

    return [
      AdherenceRecord(
        id: assessmentId * 10 + 1,
        assessmentId: assessmentId,
        adherenceType: AdherenceType.meal,
        slot: Slot.breakfast,
        isNeeded: true,
        isDone: !mealMiss,
      ),
      AdherenceRecord(
        id: assessmentId * 10 + 2,
        assessmentId: assessmentId,
        adherenceType: AdherenceType.meal,
        slot: Slot.lunch,
        isNeeded: true,
        isDone: true,
      ),
      AdherenceRecord(
        id: assessmentId * 10 + 3,
        assessmentId: assessmentId,
        adherenceType: AdherenceType.meal,
        slot: Slot.dinner,
        isNeeded: !unknownDinner,
        isDone: !unknownDinner,
      ),
      AdherenceRecord(
        id: assessmentId * 10 + 4,
        assessmentId: assessmentId,
        adherenceType: AdherenceType.medication,
        slot: Slot.breakfast,
        isNeeded: true,
        isDone: !medMiss,
      ),
      AdherenceRecord(
        id: assessmentId * 10 + 5,
        assessmentId: assessmentId,
        adherenceType: AdherenceType.medication,
        slot: Slot.lunch,
        isNeeded: false,
        isDone: false,
      ),
      AdherenceRecord(
        id: assessmentId * 10 + 6,
        assessmentId: assessmentId,
        adherenceType: AdherenceType.medication,
        slot: Slot.dinner,
        isNeeded: true,
        isDone: index % 5 != 0,
      ),
    ];
  }
}
