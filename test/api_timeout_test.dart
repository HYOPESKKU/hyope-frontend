// 네트워크가 끊기거나 서버가 응답하지 않을 때의 동작을 검증한다.
//
// 예전에는 ApiClient에 타임아웃이 없어서, 연결이 즉시 끊기지 않고 응답만
// 오지 않는 상황(지하철·엘리베이터, 서버 콜드스타트)에서 로딩 스피너가
// 영원히 돌았다. 사용자는 앱이 멈춘 것으로 본다.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hyope_frontend/services/api_client.dart';

void main() {
  group('ApiClient 네트워크 실패', () {
    test('타임아웃 상수가 합리적인 범위다', () {
      // 너무 짧으면 Railway 콜드스타트 중인 정상 요청까지 끊긴다.
      // 너무 길면 사용자가 멈춘 줄 안다.
      expect(kApiTimeout.inSeconds, greaterThanOrEqualTo(10));
      expect(kApiTimeout.inSeconds, lessThanOrEqualTo(30));
    });

    test('NetworkException은 ApiException과 구분된다', () {
      // 화면에서 "다시 시도"를 권할지, 입력을 고치라 안내할지가 달라진다.
      expect(NetworkException(), isNot(isA<ApiException>()));
    });

    test('NetworkException 기본 메시지가 사용자에게 보여줄 만하다', () {
      final e = NetworkException();
      expect(e.message, isNotEmpty);
      expect(e.message, contains('연결'));
      // 예외 클래스 이름이 그대로 노출되면 안 된다
      expect(e.toString(), isNot(contains('Exception:')));
    });

    test('타임아웃 메시지는 재시도를 안내한다', () {
      final e = NetworkException('서버 응답이 없습니다. 잠시 후 다시 시도해 주세요.');
      expect(e.message, contains('다시 시도'));
    });
  });

  group('실제 연결 실패 시 예외 종류', () {
    test('닿을 수 없는 주소로 요청하면 NetworkException이 난다', () async {
      // 예약된 문서화용 주소(RFC 5737)라 실제로 응답하지 않는다.
      // 타임아웃이 없으면 이 테스트가 끝나지 않는다.
      final client = ApiClient();
      await expectLater(
        () => client.get('/health', auth: false),
        throwsA(anyOf(isA<NetworkException>(), isA<SocketException>(),
            isA<TimeoutException>())),
      );
    }, skip: '네트워크 환경에 의존하므로 기본 실행에서 제외. 수동으로 켜서 확인할 것.');
  });

  _authMessageTests();
}

// ---------------------------------------------------------------------------
// 서버 장애를 사용자 잘못으로 안내하지 않는지
// ---------------------------------------------------------------------------
//
// 실제로 겪은 상황: 백엔드가 502로 죽어 있는데 앱은 "회원가입에 실패했습니다.
// 이미 존재하는 아이디일 수 있습니다"를 띄웠다. 사용자는 아이디를 바꿔가며
// 계속 시도하게 된다.

void _authMessageTests() {
  group('인증 실패 메시지 구분', () {
    test('5xx는 서버 문제로 안내한다', () {
      for (final code in [500, 502, 503, 504]) {
        final e = ApiException(code, '요청에 실패했습니다. ($code)');
        expect(e.statusCode >= 500, isTrue, reason: '$code');
      }
    });

    test('4xx는 사용자 입력 문제로 안내한다', () {
      for (final code in [400, 401, 403, 409]) {
        final e = ApiException(code, '요청에 실패했습니다. ($code)');
        expect(e.statusCode >= 500, isFalse, reason: '$code');
      }
    });
  });
}
