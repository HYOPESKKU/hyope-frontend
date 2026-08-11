import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

// const String kApiBaseUrl = 'http://localhost:8080';
const String kApiBaseUrl = 'https://hyope-backend-production.up.railway.app';

/// 요청 하나가 기다릴 수 있는 최대 시간.
///
/// 예전에는 타임아웃이 없어서, 연결이 즉시 끊기지 않고 응답만 오지 않는
/// 상황(지하철·엘리베이터, 서버 콜드스타트)에서 로딩 스피너가 영원히 돌았다.
/// 사용자는 앱이 멈춘 것으로 본다.
///
/// 20초로 잡은 이유: Railway 무료 플랜은 유휴 상태에서 깨어나는 데 시간이
/// 걸린다. 너무 짧으면 정상 요청까지 끊긴다.
const Duration kApiTimeout = Duration(seconds: 20);

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// 네트워크가 끊겼거나 서버가 응답하지 않을 때.
///
/// ApiException(HTTP 상태코드가 있는 실패)과 구분한다. 화면에서 "다시 시도"를
/// 권할지, 입력을 고치라고 안내할지가 달라진다.
class NetworkException implements Exception {
  final String message;

  NetworkException([this.message = '네트워크에 연결할 수 없습니다. 연결 상태를 확인해 주세요.']);

  @override
  String toString() => message;
}

/// 로그인 이후 발급받은 JWT를 앱 전역에서 들고 있는 세션.
/// TODO: 앱을 완전히 재시작해도 로그인이 유지되게 하려면
/// flutter_secure_storage 등으로 영속화하세요. 지금은 메모리에만 보관합니다.
class AuthSession {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  String? token;

  bool get isLoggedIn => token != null;

  void clear() => token = null;
}

/// 인증이 필요한 나머지 화면(recipient, assessment 등)에서
/// 공통으로 사용할 HTTP 클라이언트. 토큰이 있으면 자동으로
/// Authorization 헤더를 붙여줍니다.
class ApiClient {
  Uri _uri(String path) => Uri.parse('$kApiBaseUrl$path');

  Map<String, String> _headers({required bool auth}) {
    final headers = {'Content-Type': 'application/json'};
    final token = AuthSession.instance.token;
    if (auth && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// 모든 요청이 거치는 지점. 타임아웃과 연결 실패 처리를 여기 한 곳에 둔다.
  ///
  /// 메서드마다 따로 쓰면 하나를 빠뜨렸을 때 그 경로만 무한 대기에 빠지는데,
  /// 그런 버그는 재현이 어려워 늦게 발견된다.
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(kApiTimeout);
    } on TimeoutException {
      throw NetworkException('서버 응답이 없습니다. 잠시 후 다시 시도해 주세요.');
    } on SocketException {
      throw NetworkException();
    } on http.ClientException {
      throw NetworkException();
    }
  }

  Future<dynamic> get(String path, {bool auth = true}) async {
    final res = await _send(
      () => http.get(_uri(path), headers: _headers(auth: auth)),
    );
    return _decode(res);
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) async {
    final res = await _send(
      () => http.post(
        _uri(path),
        headers: _headers(auth: auth),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _decode(res);
  }

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) async {
    final res = await _send(
      () => http.patch(
        _uri(path),
        headers: _headers(auth: auth),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _decode(res);
  }

  Future<void> delete(String path, {bool auth = true}) async {
    final res = await _send(
      () => http.delete(_uri(path), headers: _headers(auth: auth)),
    );
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, '요청에 실패했습니다. (${res.statusCode})');
    }
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, '요청에 실패했습니다. (${res.statusCode})');
    }
    if (res.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(res.bodyBytes));
  }
}