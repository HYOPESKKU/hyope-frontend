import 'dart:math' as math;

import '../models/hyope_models.dart';
import 'date_utils.dart';

DailyAssessment? findAssessmentByDate(List<DailyAssessment> assessments, DateTime date) {
  for (final assessment in assessments) {
    if (isSameDay(assessment.measuredAt, date)) return assessment;
  }
  return null;
}

AdherenceStats calculateMonthlyAdherenceStats(
  List<DailyAssessment> assessments,
  DateTime selectedMonth,
) {
  final monthAssessments = assessments.where((assessment) {
    return assessment.measuredAt.year == selectedMonth.year &&
        assessment.measuredAt.month == selectedMonth.month;
  }).toList();

  final recordedDates = monthAssessments
      .map((assessment) => dateOnly(assessment.measuredAt))
      .toSet();
  final today = dateOnly(DateTime.now());
  final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
  var pastDaysInMonth = 0;

  for (int day = 1; day <= daysInMonth; day++) {
    final date = DateTime(selectedMonth.year, selectedMonth.month, day);
    if (!date.isAfter(today)) pastDaysInMonth++;
  }

  int neededCount(AdherenceType type) {
    return monthAssessments.expand((assessment) => assessment.adherenceRecords).where((record) {
      return record.adherenceType == type && record.isNeeded;
    }).length;
  }

  int doneCount(AdherenceType type) {
    return monthAssessments.expand((assessment) => assessment.adherenceRecords).where((record) {
      return record.adherenceType == type && record.isNeeded && record.isDone;
    }).length;
  }

  final mealNeeded = neededCount(AdherenceType.meal);
  final mealDone = doneCount(AdherenceType.meal);
  final medicationNeeded = neededCount(AdherenceType.medication);
  final medicationDone = doneCount(AdherenceType.medication);

  return AdherenceStats(
    recordedDays: recordedDates.length,
    noRecordDays: math.max(0, pastDaysInMonth - recordedDates.length),
    mealNeededCount: mealNeeded,
    mealDoneCount: mealDone,
    mealMissedCount: math.max(0, mealNeeded - mealDone),
    medicationNeededCount: medicationNeeded,
    medicationDoneCount: medicationDone,
    medicationMissedCount: math.max(0, medicationNeeded - medicationDone),
  );
}

AdherenceRecord? findAdherence(
  DailyAssessment assessment,
  AdherenceType type,
  Slot slot,
) {
  for (final record in assessment.adherenceRecords) {
    if (record.adherenceType == type && record.slot == slot) return record;
  }
  return null;
}

AdherenceAggregate aggregateAdherence(DailyAssessment? assessment, AdherenceType type) {
  if (assessment == null) return AdherenceAggregate.unknown;
  final records = assessment.adherenceRecords
      .where((record) => record.adherenceType == type && record.isNeeded)
      .toList();

  if (records.isEmpty) return AdherenceAggregate.notNeeded;
  final doneCount = records.where((record) => record.isDone).length;
  if (doneCount == records.length) return AdherenceAggregate.done;
  if (doneCount == 0) return AdherenceAggregate.missed;
  return AdherenceAggregate.partial;
}

AdherenceStatusInfo statusFromRecord(AdherenceRecord? record) {
  if (record == null) return AdherenceStatusInfo.unknown;
  if (!record.isNeeded) return AdherenceStatusInfo.notNeeded;
  return record.isDone ? AdherenceStatusInfo.done : AdherenceStatusInfo.missed;
}

double adherenceCompletionRate(DailyAssessment assessment, AdherenceType type) {
  final records = assessment.adherenceRecords
      .where((record) => record.adherenceType == type && record.isNeeded)
      .toList();
  if (records.isEmpty) return 100.0;
  final doneCount = records.where((record) => record.isDone).length;
  return doneCount / records.length * 100;
}

String adherenceRateDescription(double rate) {
  if (rate >= 90) return '양호';
  if (rate >= 60) return '부분 누락';
  return '확인 필요';
}

String riskDetailComment(
  DailyAssessment assessment,
  double mealRate,
  double medicationRate,
) {
  final signals = <String>[];
  if (assessment.healthRisk >= 4) signals.add('건강 이상 신호가 다소 높음');
  if (assessment.depressionScore >= 4) signals.add('우울 관련 표현 확인 필요');
  if (assessment.emotionalStability < 5) signals.add('정서 안정 점수 저하');
  if (assessment.cognitiveScore < 5) signals.add('인지 기능 지표 확인 필요');
  if (mealRate < 100 || medicationRate < 100) signals.add('식사·복약 일부 누락');

  if (signals.isEmpty) {
    return '현재 세부 지표는 전반적으로 안정 범위입니다. 다음 ARS 통화에서 기본 항목을 재확인하세요.';
  }
  return '${signals.join(', ')} 항목이 종합 위험도에 반영되었습니다.';
}
