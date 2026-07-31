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
    } on ApiException {
      throw AuthException('로그인에 실패했습니다. 아이디 또는 비밀번호를 확인해주세요.');
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
    } on ApiException {
      throw AuthException('회원가입에 실패했습니다. 이미 존재하는 아이디일 수 있습니다.');
    }
  }
}