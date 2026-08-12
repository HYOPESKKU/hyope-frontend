import '../models/hyope_models.dart';
import 'api_client.dart';

class GuardianService {
  final _client = ApiClient();

  /// 로그인한 본인의 프로필을 가져옵니다.
  ///
  /// 예전에는 `GET /guardians`로 전체 목록을 받아 loginId로 골라냈다. 보호자가
  /// 늘면 남의 이름·전화번호·이메일까지 앱으로 내려오므로 개인정보 문제가 있었다.
  /// 백엔드에 `/guardians/me`가 생겨(GuardianController.readMe) 그걸로 바꿨다.
  /// 서버가 JWT에서 사용자를 판별하므로 loginId를 넘길 필요도 없다.
  Future<UserProfile> findMyProfile() async {
    final json = await _client.get('/guardians/me') as Map<String, dynamic>;
    return _fromJson(json);
  }

  Future<UserProfile> updateProfile({
    required int id,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String email,
  }) async {
    final json = await _client.patch(
      '/guardians/$id',
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'email': email,
      },
    ) as Map<String, dynamic>;
    return _fromJson(json);
  }

  UserProfile _fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      role: (json['role'] as String) == 'GUARDIAN'
          ? AppUserRole.guardian
          : AppUserRole.socialWorker,
      name: '${json['lastName']}${json['firstName']}',
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String,
    );
  }
}