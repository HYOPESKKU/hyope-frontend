import 'dart:math' as math;

import '../models/hyope_models.dart';

// -----------------------------------------------------------------------------
// Mock Data: 백엔드 연결 전 화면 확인용
// -----------------------------------------------------------------------------

class MockData {
  static final guardianProfile = UserProfile(
    id: 1,
    role: AppUserRole.guardian,
    name: '김민수',
    phoneNumber: '010-9876-5432',
    email: 'guardian@hyope.kr',
  );

  static final socialWorkerProfile = UserProfile(
    id: 2,
    role: AppUserRole.socialWorker,
    name: '이지은',
    phoneNumber: '010-5555-2026',
    email: 'worker@hyope.kr',
  );

  static final guardianRecipient = RecipientSummary(
    id: 1,
    name: '김영희',
    birthDate: DateTime(1948, 3, 18),
    gender: Gender.female,
    relation: '어머니',
    phoneNumber: '010-1234-5678',
  );

  static final managedRecipients = <RecipientSummary>[
    RecipientSummary(
      id: 101,
      name: '박정수',
      birthDate: DateTime(1942, 8, 4),
      gender: Gender.male,
      relation: '담당 피보호자',
      phoneNumber: '010-2101-1001',
    ),
    RecipientSummary(
      id: 102,
      name: '이순자',
      birthDate: DateTime(1946, 11, 21),
      gender: Gender.female,
      relation: '담당 피보호자',
      phoneNumber: '010-2101-1002',
    ),
    RecipientSummary(
      id: 103,
      name: '최영식',
      birthDate: DateTime(1939, 5, 9),
      gender: Gender.male,
      relation: '담당 피보호자',
      phoneNumber: '010-2101-1003',
    ),
    RecipientSummary(
      id: 104,
      name: '한명숙',
      birthDate: DateTime(1951, 1, 30),
      gender: Gender.female,
      relation: '담당 피보호자',
      phoneNumber: '010-2101-1004',
    ),
    RecipientSummary(
      id: 105,
      name: '정기철',
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

  static List<ConversationLog> conversationLogs({int recipientId = 1}) {
    final assessments = last30Days(recipientId: recipientId);
    return assessments.map((assessment) {
      final isLowMood = assessment.depressionScore >= 5;
      final summary = isLowMood
          ? '평소보다 기운이 없어 보이셨고, 식사 여부를 확인했습니다.'
          : '전반적으로 안정적인 상태로 특이사항은 없었습니다.';

      return ConversationLog(
        id: assessment.callLogId,
        recipientId: recipientId,
        callLogId: assessment.callLogId,
        calledAt: assessment.measuredAt,
        duration: const Duration(minutes: 4, seconds: 32),
        summary: summary,
        messages: [
          ConversationMessage(
            speaker: 'ai',
            content: '안녕하세요, 오늘 컨디션은 어떠세요?',
            sentAt: assessment.measuredAt,
          ),
          ConversationMessage(
            speaker: 'recipient',
            content: isLowMood ? '오늘은 좀 기운이 없네요.' : '오늘은 괜찮아요.',
            sentAt: assessment.measuredAt.add(const Duration(seconds: 8)),
          ),
          ConversationMessage(
            speaker: 'ai',
            content: '식사는 하셨어요? 불편한 곳은 없으신가요?',
            sentAt: assessment.measuredAt.add(const Duration(seconds: 20)),
          ),
          ConversationMessage(
            speaker: 'recipient',
            content: isLowMood ? '입맛이 없어서 조금만 먹었어요.' : '네, 잘 챙겨 먹었어요.',
            sentAt: assessment.measuredAt.add(const Duration(seconds: 30)),
          ),
        ],
      );
    }).toList();
  }
}