// 대화내역 주 단위 페이지네이션의 경계 계산.
//
// 주 경계는 눈으로 확인하기 어렵다. 일요일 통화가 다음 주로 넘어가거나,
// 월요일 0시 통화가 지난 주에 남거나, 연말에 주가 해를 걸치는 경우는
// 실제 데이터가 그 시점에 쌓여야만 드러난다. 그래서 테스트로 고정한다.

import 'package:flutter_test/flutter_test.dart';

import 'package:hyope_frontend/utils/date_utils.dart';

void main() {
  group('startOfWeek', () {
    test('주중 아무 날이나 그 주 월요일을 반환한다', () {
      // 2026-08-13은 목요일. 그 주 월요일은 8/10.
      expect(startOfWeek(DateTime(2026, 8, 13)), DateTime(2026, 8, 10));
      expect(startOfWeek(DateTime(2026, 8, 10)), DateTime(2026, 8, 10));
    });

    test('일요일은 그 주의 끝이라 앞선 월요일로 간다', () {
      // 2026-08-16은 일요일. 다음 주 월요일(8/17)이 아니라 8/10이어야 한다.
      expect(startOfWeek(DateTime(2026, 8, 16)), DateTime(2026, 8, 10));
    });

    test('시각은 버리고 0시로 맞춘다', () {
      expect(startOfWeek(DateTime(2026, 8, 13, 23, 59)), DateTime(2026, 8, 10));
    });
  });

  group('isInWeek', () {
    final week = DateTime(2026, 8, 10); // 8/10(월) ~ 8/16(일)

    test('월요일 0시는 포함된다', () {
      expect(isInWeek(DateTime(2026, 8, 10, 0, 0), week), isTrue);
    });

    test('일요일 늦은 시각도 포함된다', () {
      // endOfWeek가 일요일 0시라 그것만으로 비교하면 잘리는 지점.
      expect(isInWeek(DateTime(2026, 8, 16, 23, 59), week), isTrue);
    });

    test('직전 일요일과 다음 월요일은 제외된다', () {
      expect(isInWeek(DateTime(2026, 8, 9, 23, 59), week), isFalse);
      expect(isInWeek(DateTime(2026, 8, 17, 0, 0), week), isFalse);
    });
  });

  group('formatWeekRange', () {
    test('같은 해면 연도를 생략한다', () {
      expect(formatWeekRange(DateTime(2026, 8, 13)), '8월 10일 ~ 8월 16일');
    });

    test('해를 걸치면 양쪽에 연도를 붙인다', () {
      // 2026-12-28(월) ~ 2027-01-03(일)
      expect(
        formatWeekRange(DateTime(2026, 12, 30)),
        '2026년 12월 28일 ~ 2027년 1월 3일',
      );
    });
  });

  group('주별 묶기', () {
    test('통화들이 각자의 주로 나뉘고, 빈 주는 결과가 없다', () {
      final logs = [
        DateTime(2026, 8, 12, 17, 20), // 8/10 주
        DateTime(2026, 8, 16, 9, 0),   // 8/10 주 (일요일)
        DateTime(2026, 7, 29, 10, 0),  // 7/27 주
      ];

      List<DateTime> inWeek(DateTime w) =>
          logs.where((d) => isInWeek(d, w)).toList();

      expect(inWeek(DateTime(2026, 8, 10)).length, 2);
      expect(inWeek(DateTime(2026, 7, 27)).length, 1);
      // 8/3 주에는 통화가 없다 — 화면에서 "이 주에는 대화내역이 없습니다"가 뜨는 경우.
      expect(inWeek(DateTime(2026, 8, 3)), isEmpty);
    });
  });
}
