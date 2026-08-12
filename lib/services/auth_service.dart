import 'api_client.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  final _client = ApiClient();

  void logout() {
    AuthSession.instance.clear();
  }

  Future<String> login({
    required String loginId,
    required String password,
  }) async {
    try {
      final body = await _client.post(
        '/auth/login',
        auth: false,
        body: {'loginId': loginId, 'password': password},
      ) as Map<String, dynamic>;

      final token = body['token'] as String;
      AuthSession.instance.token = token;
      return token;
    } on ApiException catch (e) {
      throw AuthException(_authFailureMessage(e, '로그인에 실패했습니다. 아이디 또는 비밀번호를 확인해주세요.'));
    }
  }

  Future<void> register({
    required String loginId,
    required String password,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required String phoneNumber,
    required String email,
    required String gender, // 'MALE' | 'FEMALE'
    required String role, // 'GUARDIAN' | 'ORG_ADMIN'
  }) async {
    try {
      await _client.post(
        '/auth/register',
        auth: false,
        body: {
          'loginId': loginId,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'birthDate': birthDate.toIso8601String().split('T').first,
          'phoneNumber': phoneNumber,
          'email': email,
          'gender': gender,
          'role': role,
        },
      );
    } on ApiException catch (e) {
      throw AuthException(_authFailureMessage(e, '회원가입에 실패했습니다. 이미 존재하는 아이디일 수 있습니다.'));
    }
  }

  /// 서버 장애를 사용자 잘못으로 안내하지 않도록 상태코드로 갈라준다.
  ///
  /// 예전에는 `on ApiException`이 상태코드를 보지 않고 전부 "아이디/비밀번호를
  /// 확인해주세요"로 바꿨다. 백엔드가 502로 죽어 있는 동안 앱은 계속
  /// "이미 존재하는 아이디일 수 있습니다"라고 안내했고, 사용자는 아이디를
  /// 바꿔가며 계속 시도하게 된다.
  String _authFailureMessage(ApiException e, String userInputMessage) {
    if (e.statusCode >= 500) {
      return '서버에 문제가 생겼습니다. 잠시 후 다시 시도해 주세요.';
    }
    return userInputMessage;
  }
}