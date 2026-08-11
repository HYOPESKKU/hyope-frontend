// 통화가 실패하거나 필수 질문에 답이 안 들어왔을 때 앱이 죽지 않는지 검증한다.
//
// 배경: 백엔드는 통화가 정상적으로 안 끝나도 결과를 보낸다. 채점 서비스가
// 아직 연결되지 않았을 때는 measured_at이 null인 placeholder가 나가고,
// 어르신이 답을 안 하면 카테고리 판정이 "알수없음"으로 남는다.
// 신규 어르신은 평가 기록이 아예 0건이다.
//
// 이 테스트들은 고치기 전에는 실패하는 게 정상이다.

import 'package:flutter_test/flutter_test.dart';
import 'package:hyope_frontend/models/hyope_models.dart';

/// 정상 응답 — 비교 기준
Map<String, dynamic> okAssessment() => {
      'id': 1,
      'recipientId': 1,
      'callLogId': 10,
      'measuredAt': '2026-08-11T09:00:00',
      'depressionScore': 6.0,
      'emotionalStability': 8.0,
      'healthRisk': 7.0,
      'cognitiveScore': 9.0,
      'overallRisk': 4.0,
      'riskLevel': 'CAUTION',
      'summary': '신체건강 우려',
      'recommendation': '전화 권장',
      'adherenceRecords': <dynamic>[],
    };

void main() {
  group('DailyAssessment.fromJson — 통화 실패 케이스', () {
    test('measuredAt이 null이어도 파싱된다', () {
      // 채점 서비스 미연결 시 placeholder가 measured_at: null을 보낸다.
      final json = okAssessment()..['measuredAt'] = null;
      expect(() => DailyAssessment.fromJson(json), returnsNormally);
    });

    test('measuredAt 키가 아예 없어도 파싱된다', () {
      final json = okAssessment()..remove('measuredAt');
      expect(() => DailyAssessment.fromJson(json), returnsNormally);
    });

    test('measured_at (snake_case)로 와도 읽는다', () {
      // 다른 필드는 두 표기를 모두 받는데 measuredAt만 camelCase만 본다.
      final json = okAssessment()
        ..remove('measuredAt')
        ..['measured_at'] = '2026-08-11T09:00:00';
      final a = DailyAssessment.fromJson(json);
      expect(a.measuredAt.year, 2026);
      expect(a.measuredAt.month, 8);
      expect(a.measuredAt.day, 11);
    });

    test('날짜 형식이 깨져도 죽지 않는다', () {
      final json = okAssessment()..['measuredAt'] = 'not-a-date';
      expect(() => DailyAssessment.fromJson(json), returnsNormally);
    });

    test('점수가 전부 null이어도 파싱된다', () {
      // 필수 질문에 답이 없으면 백엔드가 점수를 못 낸다.
      final json = okAssessment();
      for (final k in [
        'depressionScore',
        'emotionalStability',
        'healthRisk',
        'cognitiveScore',
        'overallRisk',
      ]) {
        json[k] = null;
      }
      expect(() => DailyAssessment.fromJson(json), returnsNormally);
    });

    test('adherenceRecords가 null이어도 파싱된다', () {
      final json = okAssessment()..['adherenceRecords'] = null;
      final a = DailyAssessment.fromJson(json);
      expect(a.adherenceRecords, isEmpty);
    });
  });

  group('ConversationLog — 통화 중단 케이스', () {
    test('startedAt이 null이어도 파싱된다 (발신 자체가 실패)', () {
      expect(
        () => ConversationLog.fromJson({
          'id': 1,
          'recipientId': 1,
          'startedAt': null,
          'endedAt': null,
          'durationSec': 0,
          'status': 'FAILED',
        }),
        returnsNormally,
      );
    });

    test('askedAt이 null인 메시지도 파싱된다 (무응답)', () {
      expect(
        () => ConversationMessage.fromJson({
          'callLogId': 1,
          'sequence': 1,
          'question': '오늘 약은 드셨나요?',
          'answer': null,
          'askedAt': null,
        }),
        returnsNormally,
      );
    });
  });
}
