import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// Models: 백엔드 DTO와 최대한 비슷하게 맞춘 프론트엔드 모델
// -----------------------------------------------------------------------------

enum RiskLevel { observe, caution, warning, high }

enum AdherenceType { meal, medication }

enum Slot { breakfast, lunch, dinner }

enum AdherenceAggregate { done, partial, missed, unknown, notNeeded }

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

class RecipientSummary {
  final int id;
  final String name;
  final String relation;
  final String phoneNumber;

  const RecipientSummary({
    required this.id,
    required this.name,
    required this.relation,
    required this.phoneNumber,
  });
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
  final String recommendation;
  final List<AdherenceRecord> adherenceRecords;

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
    required this.recommendation,
    required this.adherenceRecords,
  });

  // 백엔드 연결 시 사용 가능.
  factory DailyAssessment.fromJson(Map<String, dynamic> json) {
    return DailyAssessment(
      id: _toInt(json['id'] ?? json['assessment_id'] ?? 0),
      recipientId: _toInt(json['recipient_id'] ?? json['recipientId'] ?? 0),
      callLogId: _toInt(json['call_log_id'] ?? json['callLogId'] ?? 0),
      measuredAt: DateTime.parse(json['measuredAt'] as String),
      depressionScore: _toDouble(json['depressionScore']),
      emotionalStability: _toDouble(json['emotionalStability']),
      healthRisk: _toDouble(json['healthRisk']),
      cognitiveScore: _toDouble(json['cognitiveScore']),
      overallRisk: _toDouble(json['overallRisk']),
      riskLevel: parseRiskLevel(json['riskLevel'] as String? ?? 'OBSERVE'),
      recommendation: json['recommendation'] as String? ?? '',
      adherenceRecords: const [],
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
      isNeeded: json['isNeeded'] as bool? ?? false,
      isDone: json['isDone'] as bool? ?? false,
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
