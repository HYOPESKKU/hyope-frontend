import 'dart:convert';
import 'package:http/http.dart' as http;

// const String kApiBaseUrl = 'http://localhost:8080';
const String kApiBaseUrl = 'https://hyope-backend-production.up.railway.app';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

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

  Future<dynamic> get(String path, {bool auth = true}) async {
    final res = await http.get(_uri(path), headers: _headers(auth: auth));
    return _decode(res);
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) async {
    final res = await http.post(
      _uri(path),
      headers: _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) async {
    final res = await http.patch(
      _uri(path),
      headers: _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<void> delete(String path, {bool auth = true}) async {
    final res = await http.delete(_uri(path), headers: _headers(auth: auth));
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