import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// Models: 백엔드 DTO와 최대한 비슷하게 맞춘 프론트엔드 모델
// -----------------------------------------------------------------------------

enum AppUserRole { guardian, socialWorker }

enum Gender { male, female }

enum RiskLevel { observe, caution, warning, high }

enum AdherenceType { meal, medication }

enum Slot { breakfast, lunch, dinner }

enum AdherenceAggregate { done, partial, missed, unknown, notNeeded }


extension AppUserRoleView on AppUserRole {
  String get label {
    switch (this) {
      case AppUserRole.guardian:
        return '보호자';
      case AppUserRole.socialWorker:
        return '복지사';
    }
  }
}

extension GenderView on Gender {
  String get label {
    switch (this) {
      case Gender.male:
        return '남성';
      case Gender.female:
        return '여성';
    }
  }
}

extension RiskLevelView on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.observe:
        return '관찰';
      case RiskLevel.caution:
        return '주의';
      case RiskLevel.warning:
        return '경고';
      case RiskLevel.high:
        return '고위험';
    }
  }

  String get actionTitle {
    switch (this) {
      case RiskLevel.observe:
        return '관찰 유지';
      case RiskLevel.caution:
        return '전화 권장';
      case RiskLevel.warning:
        return '전화 + 방문 고려';
      case RiskLevel.high:
        return '즉시 연락 필요';
    }
  }

  String get actionDescription {
    switch (this) {
      case RiskLevel.observe:
        return '정상 범위입니다. 다음 통화에서 식사·복약 여부를 다시 확인하세요.';
      case RiskLevel.caution:
        return '오늘 중 보호자 전화가 권장됩니다. 우울감, 통증, 식사 여부를 짧게 확인하세요.';
      case RiskLevel.warning:
        return '전화 후 상태가 좋지 않으면 방문을 고려하세요. 돌봄 공백 여부를 확인하세요.';
      case RiskLevel.high:
        return '즉시 연락하고 응답이 없거나 급성 증상이 의심되면 긴급 대응을 검토하세요.';
    }
  }

  IconData get icon {
    switch (this) {
      case RiskLevel.observe:
        return Icons.visibility_outlined;
      case RiskLevel.caution:
        return Icons.phone_in_talk_outlined;
      case RiskLevel.warning:
        return Icons.home_work_outlined;
      case RiskLevel.high:
        return Icons.emergency_outlined;
    }
  }

  Color get color {
    switch (this) {
      case RiskLevel.observe:
        return const Color(0xFF2FB86E);
      case RiskLevel.caution:
        return const Color(0xFFE5A900);
      case RiskLevel.warning:
        return const Color(0xFFFF8A3D);
      case RiskLevel.high:
        return const Color(0xFFE74747);
    }
  }
}

extension SlotView on Slot {
  String get label {
    switch (this) {
      case Slot.breakfast:
        return '아침';
      case Slot.lunch:
        return '점심';
      case Slot.dinner:
        return '저녁';
    }
  }
}

extension AdherenceAggregateView on AdherenceAggregate {
  Color get aggregateColor {
    switch (this) {
      case AdherenceAggregate.done:
        return const Color(0xFF2FB86E);
      case AdherenceAggregate.partial:
        return const Color(0xFFE5A900);
      case AdherenceAggregate.missed:
        return const Color(0xFFE74747);
      case AdherenceAggregate.unknown:
      case AdherenceAggregate.notNeeded:
        return const Color(0xFF9AA2B4);
    }
  }
}

class UserProfile {
  final int id;
  final AppUserRole role;

  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;

  const UserProfile({
    required this.id,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
  });

  /// 화면 표시용으로 합친 이름.
  ///
  /// 필드로 따로 갖고 있지 않고 매번 만든다. 예전에는 합친 값을 필드로 두고
  /// 수정 화면에서 첫 글자를 잘라 성을 되찾았는데, 남궁·황보 같은 복성이
  /// `남` + `궁민준`으로 깨졌고 그대로 저장하면 서버 이름까지 오염됐다.
  /// 성/이름을 원본 그대로 두면 되돌릴 일 자체가 없어진다.
  String get name => '$lastName$firstName';

  UserProfile copyWith({
    int? id,
    AppUserRole? role,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? email,
  }) {
    return UserProfile(
      id: id ?? this.id,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
    );
  }
}

class RecipientSummary {
  final int id;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final Gender gender;
  final String relation;
  final String phoneNumber;
  final String? address;
  final List<String> hobbies;
  final List<String> recentEvents;

  const RecipientSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.gender,
    required this.relation,
    required this.phoneNumber,
    this.address,
    this.hobbies = const [],
    this.recentEvents = const [],
  });

  RecipientSummary copyWith({
    int? id,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    Gender? gender,
    String? relation,
    String? phoneNumber,
    String? address,
    List<String>? hobbies,
    List<String>? recentEvents,
  }) {
    return RecipientSummary(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      relation: relation ?? this.relation,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      hobbies: hobbies ?? this.hobbies,
      recentEvents: recentEvents ?? this.recentEvents,
    );
  }

  /// 화면 표시용으로 합친 이름. UserProfile.name과 같은 이유로 getter다.
  String get name => '$lastName$firstName';

  int get age => calculateAge(birthDate);

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0];
}

int calculateAge(DateTime birthDate) {
  final today = DateTime.now();
  var result = today.year - birthDate.year;
  final birthdayHasPassed = today.month > birthDate.month ||
      (today.month == birthDate.month && today.day >= birthDate.day);
  if (!birthdayHasPassed) result--;
  return result;
}

class CallSchedule {
  final int id;
  final int recipientId;
  final bool isActive;
  final TimeOfDay scheduledTime;
  final int? intervalDays;

  const CallSchedule({
    required this.id,
    required this.recipientId,
    required this.isActive,
    required this.scheduledTime,
    this.intervalDays,
  });

  factory CallSchedule.fromJson(Map<String, dynamic> json) {
    return CallSchedule(
      id: _toInt(json['id']),
      recipientId: _toInt(json['recipient_id'] ?? json['recipientId']),
      isActive: json['isActive'] as bool? ?? true,
      scheduledTime: parseTimeOfDay(json['scheduledTime'] as String),
      intervalDays: json['intervalDays'] as int?,
    );
  }
}

TimeOfDay parseTimeOfDay(String value) {
  final parts = value.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

String formatTimeOfDayForApi(TimeOfDay time) {
  final hh = time.hour.toString().padLeft(2, '0');
  final mm = time.minute.toString().padLeft(2, '0');
  return '$hh:$mm:00';
}

String formatTimeOfDayKo(TimeOfDay time) {
  final isAm = time.hour < 12;
  final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '${isAm ? '오전' : '오후'} $hour12:$minute';
}

class DailyAssessment {
  final int id;
  final int recipientId;
  final int callLogId;
  final DateTime measuredAt;
  final double depressionScore;
  final double emotionalStability;
  final double healthRisk;
  final double cognitiveScore;
  final double overallRisk;
  final RiskLevel riskLevel;
  final String summary;
  final String recommendation;
  final List<AdherenceRecord> adherenceRecords;
  final List<String> incompleteCategories;

  const DailyAssessment({
    required this.id,
    required this.recipientId,
    required this.callLogId,
    required this.measuredAt,
    required this.depressionScore,
    required this.emotionalStability,
    required this.healthRisk,
    required this.cognitiveScore,
    required this.overallRisk,
    required this.riskLevel,
    required this.summary,
    required this.recommendation,
    required this.adherenceRecords,
    this.incompleteCategories = const [],
  });

  /// 날짜를 못 받은 기록. 발신 자체가 실패했을 때 이렇게 온다.
  ///
  /// 파싱 단계에서 epoch로 대체하므로(_toDate) 1970년이면 실제 날짜가 아니다.
  bool get hasNoDate => measuredAt.isBefore(DateTime(2000));

  /// 채점이 이뤄지지 않은 기록.
  ///
  /// 채점 서비스가 연결되기 전에는 백엔드가 모든 점수를 0.5로 채운
  /// placeholder를 보낸다. 실제 측정값이 다섯 지표 모두 정확히 0.5로 나오는
  /// 일은 사실상 없으므로 이 조합을 미채점으로 본다.
  bool get isPlaceholder =>
      depressionScore == 0.5 &&
      emotionalStability == 0.5 &&
      healthRisk == 0.5 &&
      cognitiveScore == 0.5 &&
      overallRisk == 0.5;

  /// 이 날의 점수를 추이 그래프에 그려도 되는가.
  ///
  /// 통화가 실패했거나 어르신이 답을 안 한 날의 점수는 측정값이 아니라
  /// 기본값이다. 그대로 선을 이으면 보호자가 "이 날 좋아졌다/나빠졌다"로
  /// 읽는데, 실제로는 **측정을 못 한 날**이다. 오해를 부르므로 그래프에서
  /// 끊어서 표시한다.
  bool get isMeasured => !hasNoDate && !isPlaceholder;

  bool isCategoryComplete(String categoryKey) {
    return !incompleteCategories.contains(categoryKey);
  }

  factory DailyAssessment.fromJson(Map<String, dynamic> json) {
    final rawAdherenceRecords = json['adherenceRecords'];
    final adherenceRecords = rawAdherenceRecords is List
        ? rawAdherenceRecords
            .whereType<Map>()
            .map(
              (record) => AdherenceRecord.fromJson(
                Map<String, dynamic>.from(record),
              ),
            )
            .toList()
        : <AdherenceRecord>[];

    final rawIncompleteCategories =
        json['incompleteCategories'] ?? json['incomplete_categories'];
    final incompleteCategories = rawIncompleteCategories is List
        ? rawIncompleteCategories.map((e) => e.toString()).toList()
        : const <String>[];

    return DailyAssessment(
      id: _toInt(json['id'] ?? json['assessment_id'] ?? 0),
      recipientId: _toInt(json['recipient_id'] ?? json['recipientId'] ?? 0),
      callLogId: _toInt(json['call_log_id'] ?? json['callLogId'] ?? 0),
      measuredAt: _toDate(json['measuredAt'] ?? json['measured_at']),
      depressionScore: _toDouble(json['depressionScore']),
      emotionalStability: _toDouble(json['emotionalStability']),
      healthRisk: _toDouble(json['healthRisk']),
      cognitiveScore: _toDouble(json['cognitiveScore']),
      overallRisk: _toDouble(json['overallRisk']),
      riskLevel: parseRiskLevel(json['riskLevel'] as String? ?? 'OBSERVE'),
      summary: json['summary'] as String? ?? '',
      recommendation: json['recommendation'] as String? ?? '',
      adherenceRecords: adherenceRecords,
      incompleteCategories: incompleteCategories,
    );
  }
}

class AdherenceRecord {
  final int id;
  final int assessmentId;
  final AdherenceType adherenceType;
  final Slot slot;
  final bool isNeeded;
  final bool isDone;

  const AdherenceRecord({
    required this.id,
    required this.assessmentId,
    required this.adherenceType,
    required this.slot,
    required this.isNeeded,
    required this.isDone,
  });

  factory AdherenceRecord.fromJson(Map<String, dynamic> json) {
    return AdherenceRecord(
      id: _toInt(json['id']),
      assessmentId: _toInt(json['assessment_id'] ?? json['assessmentId']),
      adherenceType: parseAdherenceType(json['adherenceType'] as String? ?? 'MEAL'),
      slot: parseSlot(json['slot'] as String? ?? 'BREAKFAST'),
      // Jackson/Lombok 조합에 따라 needed/done 또는 isNeeded/isDone으로
      // 내려올 수 있으므로 두 형태를 모두 처리한다.
      isNeeded: _toBool(
        json['isNeeded'] ?? json['needed'] ?? json['is_needed'],
      ),
      isDone: _toBool(
        json['isDone'] ?? json['done'] ?? json['is_done'],
      ),
    );
  }
}

class AdherenceStats {
  final int recordedDays;
  final int noRecordDays;
  final int mealNeededCount;
  final int mealDoneCount;
  final int mealMissedCount;
  final int medicationNeededCount;
  final int medicationDoneCount;
  final int medicationMissedCount;

  const AdherenceStats({
    required this.recordedDays,
    required this.noRecordDays,
    required this.mealNeededCount,
    required this.mealDoneCount,
    required this.mealMissedCount,
    required this.medicationNeededCount,
    required this.medicationDoneCount,
    required this.medicationMissedCount,
  });

  double get mealRate => _safeRate(mealDoneCount, mealNeededCount);
  double get medicationRate => _safeRate(medicationDoneCount, medicationNeededCount);

  int get totalNeededCount => mealNeededCount + medicationNeededCount;
  int get totalDoneCount => mealDoneCount + medicationDoneCount;
  int get totalMissedCount => mealMissedCount + medicationMissedCount;
  double get overallRate => _safeRate(totalDoneCount, totalNeededCount);

  String get comment {
    if (recordedDays == 0) return '선택한 월에 분석 기록이 없어 이행률을 계산할 수 없습니다.';
    if (overallRate >= 90) return '이번 달 식사와 복약 이행 상태가 전반적으로 양호합니다.';
    if (overallRate >= 70) return '일부 누락이 있어 다음 통화나 보호자 연락에서 확인이 필요합니다.';
    return '이행률이 낮습니다. 식사·복약 누락 원인을 우선 확인하는 것이 좋습니다.';
  }

  static double _safeRate(int done, int total) {
    if (total == 0) return 0.0;
    return done / total * 100;
  }
}

class AdherenceStatusInfo {
  final String label;
  final Color color;
  final IconData icon;

  const AdherenceStatusInfo({
    required this.label,
    required this.color,
    required this.icon,
  });

  static const done = AdherenceStatusInfo(
    label: '완료',
    color: Color(0xFF2FB86E),
    icon: Icons.check_circle,
  );
  static const missed = AdherenceStatusInfo(
    label: '미완료',
    color: Color(0xFFE74747),
    icon: Icons.cancel,
  );
  static const unknown = AdherenceStatusInfo(
    label: '미확인',
    color: Color(0xFF9AA2B4),
    icon: Icons.help,
  );
  static const notNeeded = AdherenceStatusInfo(
    label: '불필요',
    color: Color(0xFF9AA2B4),
    icon: Icons.remove_circle,
  );
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

/// 날짜를 안전하게 파싱한다. null·빈 값·형식 오류면 null을 돌려준다.
///
/// 통화가 실패하거나 어르신이 답을 안 하면 백엔드가 날짜 없이 결과를 보낸다.
/// 채점 서비스가 연결되기 전에는 measured_at이 null로 나가기도 한다.
/// 예전에는 `DateTime.parse(json['measuredAt'] as String)`이 그대로 예외를
/// 던졌는데, 목록을 Future.wait으로 묶어 받는 구조라 항목 하나가 깨지면
/// 화면 전체가 오류가 됐다.
DateTime? _toDateOrNull(dynamic value) {
  if (value is DateTime) return value;
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return null;
  return DateTime.tryParse(text);
}

/// 날짜가 반드시 필요한 자리용. 없으면 [fallback], 그것도 없으면 epoch를 쓴다.
///
/// epoch(1970-01-01)를 쓰는 이유: 화면이 날짜순으로 정렬하는데, 날짜를
/// 못 읽은 항목을 현재 시각으로 채우면 최신 기록인 척 맨 위에 올라온다.
/// epoch면 맨 뒤로 밀려 오해를 부르지 않는다.
DateTime _toDate(dynamic value, {DateTime? fallback}) =>
    _toDateOrNull(value) ??
    fallback ??
    DateTime.fromMillisecondsSinceEpoch(0);

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;

  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1';
}

RiskLevel parseRiskLevel(String value) {
  switch (value.toUpperCase()) {
    case 'CAUTION':
      return RiskLevel.caution;
    case 'WARNING':
      return RiskLevel.warning;
    case 'HIGH':
      return RiskLevel.high;
    case 'OBSERVE':
    default:
      return RiskLevel.observe;
  }
}

RiskLevel riskLevelFromScore(double score) {
  if (score <= 2) return RiskLevel.observe;
  if (score <= 5) return RiskLevel.caution;
  if (score <= 7) return RiskLevel.warning;
  return RiskLevel.high;
}

AdherenceType parseAdherenceType(String value) {
  return value.toUpperCase() == 'MEDICATION'
      ? AdherenceType.medication
      : AdherenceType.meal;
}

Slot parseSlot(String value) {
  switch (value.toUpperCase()) {
    case 'LUNCH':
      return Slot.lunch;
    case 'DINNER':
      return Slot.dinner;
    case 'BREAKFAST':
    default:
      return Slot.breakfast;
  }
}

enum CallStatus { analyzing, completed, failed, missed }

extension CallStatusView on CallStatus {
  String get label {
    switch (this) {
      case CallStatus.analyzing:
        return '분석중';
      case CallStatus.completed:
        return '완료';
      case CallStatus.failed:
        return '실패';
      case CallStatus.missed:
        return '부재중';
    }
  }
}

CallStatus parseCallStatus(String value) {
  switch (value.toUpperCase()) {
    case 'COMPLETED':
      return CallStatus.completed;
    case 'FAILED':
      return CallStatus.failed;
    case 'MISSED':
      return CallStatus.missed;
    case 'ANALYZING':
    default:
      return CallStatus.analyzing;
  }
}

class ConversationLog {
  final int id;
  final int recipientId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSec;
  final CallStatus status;

  const ConversationLog({
    required this.id,
    required this.recipientId,
    required this.startedAt,
    required this.endedAt,
    required this.durationSec,
    required this.status,
  });

  factory ConversationLog.fromJson(Map<String, dynamic> json) {
    return ConversationLog(
      id: _toInt(json['id']),
      recipientId: _toInt(json['recipient_id'] ?? json['recipientId']),
      startedAt: _toDate(json['startedAt'] ?? json['started_at']),
      endedAt: _toDateOrNull(json['endedAt'] ?? json['ended_at']),
      durationSec: _toInt(json['durationSec']),
      status: parseCallStatus(json['status'] as String? ?? 'ANALYZING'),
    );
  }
}

class ConversationMessage {
  final int callLogId;
  final int sequence;
  final String question;
  final String answer;
  final DateTime askedAt;

  const ConversationMessage({
    required this.callLogId,
    required this.sequence,
    required this.question,
    required this.answer,
    required this.askedAt,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      callLogId: _toInt(json['call_log_id'] ?? json['callLogId']),
      sequence: _toInt(json['sequence']),
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      askedAt: _toDate(json['askedAt'] ?? json['asked_at']),
    );
  }
}

enum NotificationCategory { callMissed, callFailed, highRisk, suddenSpike, incompleteAnalysis, newReport, dailyCallMissing }

NotificationCategory parseNotificationCategory(String value) {
  switch (value.toUpperCase()) {
    case 'CALL_FAILED':
      return NotificationCategory.callFailed;
    case 'HIGH_RISK':
      return NotificationCategory.highRisk;
    case 'SUDDEN_SPIKE':
      return NotificationCategory.suddenSpike;
    case 'INCOMPLETE_ANALYSIS':
      return NotificationCategory.incompleteAnalysis;
    case 'NEW_REPORT':
      return NotificationCategory.newReport;
    case 'DAILY_CALL_MISSING':
      return NotificationCategory.dailyCallMissing;
    case 'BOTH':
      return NotificationCategory.highRisk;
    case 'CALL_MISSED':
    default:
      return NotificationCategory.callMissed;
  }
}

class GuardianNotification {
  final int id;
  final int recipientId;
  final NotificationCategory type;
  final String message;
  final String? detail;
  final bool isRead;
  final DateTime createdAt;

  const GuardianNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.message,
    this.detail,
    required this.isRead,
    required this.createdAt,
  });

  GuardianNotification copyWith({bool? isRead}) {
    return GuardianNotification(
      id: id,
      recipientId: recipientId,
      type: type,
      message: message,
      detail: detail,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  factory GuardianNotification.fromJson(Map<String, dynamic> json) {
    return GuardianNotification(
      id: _toInt(json['id']),
      recipientId: _toInt(json['recipient_id'] ?? json['recipientId']),
      type: parseNotificationCategory(json['type'] as String? ?? 'CALL_MISSED'),
      message: json['message'] as String? ?? '',
      detail: json['detail'] as String?,
      isRead: json['isRead'] as bool? ?? json['is_read'] as bool? ?? json['read'] as bool? ?? false,
      createdAt: _toDate(json['createdAt'] ?? json['created_at']),
    );
  }
}