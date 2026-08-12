import 'dart:math' as math;

import '../models/hyope_models.dart';

// -----------------------------------------------------------------------------
// Mock Data: 백엔드 연결 전 화면 확인용
// -----------------------------------------------------------------------------

class MockData {
  static final guardianProfile = UserProfile(
    id: 1,
    role: AppUserRole.guardian,
    firstName: '민수',
    lastName: '김',
    phoneNumber: '010-9876-5432',
    email: 'guardian@hyope.kr',
  );

  static final socialWorkerProfile = UserProfile(
    id: 2,
    role: AppUserRole.socialWorker,
    firstName: '지은',
    lastName: '이',
    phoneNumber: '010-5555-2026',
    email: 'worker@hyope.kr',
  );

  static final guardianRecipient = RecipientSummary(
    id: 1,
    firstName: '영희',
    lastName: '김',
    birthDate: DateTime(1948, 3, 18),
    gender: Gender.female,
    relation: '어머니',
    phoneNumber: '010-1234-5678',
  );

  static final managedRecipients = <RecipientSummary>[
    RecipientSummary(
      id: 101,
      firstName: '정수',
      lastName: '박',
      birthDate: DateTime(1942, 8, 4),
      gender: Gender.male,
      relation: '담당 피보호자',
      phoneNumber: '010-2101-1001',
    ),
    RecipientSummary(
      id: 102,
      firstName: '순자',
      lastName: '이',
      birthDate: DateTime(1946, 11, 21),
      gender: Gender.female,
      relation: '담당 피보호자',
      phoneNumber: '010-2101-1002',
    ),
    RecipientSummary(
      id: 103,
      firstName: '영식',
      lastName: '최',
      birthDate: DateTime(1939, 5, 9),
      gender: Gender.male,
      relation: '담당 피보호자',
      phoneNumber: '010-2101-1003',
    ),
    RecipientSummary(
      id: 104,
      firstName: '명숙',
      lastName: '한',
      birthDate: DateTime(1951, 1, 30),
      gender: Gender.female,
      relation: '담당 피보호자',
      phoneNumber: '010-2101-1004',
    ),
    RecipientSummary(
      id: 105,
      firstName: '기철',
      lastName: '정',
      birthDate: DateTime(1944, 6, 16),
      gender: Gender.male,
      relation: '담당 피보호자',
      phoneNumber: '010-2101-1005',
    ),
  ];

  static List<DailyAssessment> last30Days({int recipientId = 1}) {
    final today = DateTime.now();
    final List<DailyAssessment> result = [];
    final recipientBias = ((recipientId * 17) % 6) * 0.38;
    final emotionBias = ((recipientId * 11) % 4) * 0.22;

    for (int i = 0; i < 30; i++) {
      final date = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 29 - i));

      final wave = math.sin((i + recipientId % 5) / 3.2) * 0.9;
      final healthRisk =
          (2.0 + recipientBias + wave + (i % 9 == 0 ? 1.2 : 0.0))
              .clamp(0.0, 10.0)
              .toDouble();
      final emotional =
          (7.1 - emotionBias - wave + (i % 10 == 3 ? -1.5 : 0.0))
              .clamp(0.0, 10.0)
              .toDouble();
      final depression =
          (10 - emotional + 0.7).clamp(0.0, 10.0).toDouble();
      final cognitive =
          (7.0 + math.cos((i + recipientId % 3) / 4.0) * 0.7)
              .clamp(0.0, 10.0)
              .toDouble();
      final missedPenalty =
          (i % 7 == 0 ? 1.0 : 0.0) + (i % 11 == 0 ? 1.3 : 0.0);
      final overallRisk =
          (healthRisk * 0.45 + depression * 0.25 + missedPenalty + 1.0)
              .clamp(0.0, 10.0)
              .toDouble();
      final risk = riskLevelFromScore(overallRisk);
      final assessmentId = recipientId * 100 + i + 1;

      result.add(
        DailyAssessment(
          id: assessmentId,
          recipientId: recipientId,
          callLogId: assessmentId,
          measuredAt: DateTime(date.year, date.month, date.day, 7, 4),
          depressionScore: depression,
          emotionalStability: emotional,
          healthRisk: healthRisk,
          cognitiveScore: cognitive,
          overallRisk: overallRisk,
          riskLevel: risk,
          summary: risk == RiskLevel.observe
              ? '전반적으로 안정적인 상태로 특이사항은 없었습니다.'
              : '평소보다 기운이 없어 보이셨고, 식사 여부를 확인했습니다.',
          recommendation: risk.actionDescription,
          adherenceRecords: _adherenceRecords(
            assessmentId,
            i + recipientId,
          ),
        ),
      );
    }
    return result;
  }

  static List<AdherenceRecord> _adherenceRecords(
    int assessmentId,
    int index,
  ) {
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

  /// 통화가 정상적으로 안 끝난 날들을 섞은 목록.
  ///
  /// 정상 데이터만으로는 fail case를 확인할 수 없다. 백엔드는 통화가 실패해도
  /// 결과를 보내는데, 그때 값이 이렇게 들어온다.
  ///   - 채점 서비스 미연결: 모든 점수 0.5, risk_level "LOW"
  ///   - 무응답: 점수는 나오지만 판정이 "알수없음"이라 요약이 비어 있음
  ///   - 발신 실패: 날짜조차 없음 (파싱 단계에서 epoch로 대체됨)
  static List<DailyAssessment> withFailCases({int recipientId = 1}) {
    final base = last30Days(recipientId: recipientId);
    if (base.length < 4) return base;

    final today = DateTime.now();
    DateTime dayAgo(int n) =>
        DateTime(today.year, today.month, today.day, 7, 4)
            .subtract(Duration(days: n));

    // 어제 — 채점 서비스가 아직 안 붙었을 때 나가는 placeholder
    final placeholder = DailyAssessment(
      id: recipientId * 100 + 901,
      recipientId: recipientId,
      callLogId: recipientId * 100 + 901,
      measuredAt: dayAgo(1),
      depressionScore: 0.5,
      emotionalStability: 0.5,
      healthRisk: 0.5,
      cognitiveScore: 0.5,
      overallRisk: 0.5,
      riskLevel: RiskLevel.observe,
      summary: '채점 미연동 — placeholder 값입니다.',
      recommendation: '채점 서비스 연동 후 재확인 필요.',
      adherenceRecords: const [],
    );

    // 이틀 전 — 어르신이 대부분 답을 안 함
    final noAnswer = DailyAssessment(
      id: recipientId * 100 + 902,
      recipientId: recipientId,
      callLogId: recipientId * 100 + 902,
      measuredAt: dayAgo(2),
      depressionScore: 5.0,
      emotionalStability: 5.0,
      healthRisk: 5.0,
      cognitiveScore: 5.0,
      overallRisk: 5.0,
      riskLevel: RiskLevel.caution,
      summary: '',
      recommendation: '',
      adherenceRecords: const [],
      incompleteCategories: const ['우울', '불안', '인지기능'],
    );

    // 사흘 전 — 발신 자체가 실패해 날짜가 없던 기록(파싱에서 epoch로 대체)
    final noDate = DailyAssessment(
      id: recipientId * 100 + 903,
      recipientId: recipientId,
      callLogId: recipientId * 100 + 903,
      measuredAt: DateTime.fromMillisecondsSinceEpoch(0),
      depressionScore: 0,
      emotionalStability: 0,
      healthRisk: 0,
      cognitiveScore: 0,
      overallRisk: 0,
      riskLevel: RiskLevel.observe,
      summary: '',
      recommendation: '',
      adherenceRecords: const [],
    );

    final result = [...base]
      ..removeWhere((a) =>
          a.measuredAt.day == dayAgo(1).day || a.measuredAt.day == dayAgo(2).day)
      ..addAll([placeholder, noAnswer, noDate])
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    return result;
  }
}
