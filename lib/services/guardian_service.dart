import '../models/hyope_models.dart';
import 'api_client.dart';

class GuardianService {
  final _client = ApiClient();

  /// GET /guardians 전체 목록에서 loginId로 내 정보를 찾습니다.
  /// TODO: 백엔드에 "내 정보 조회(me)" 엔드포인트가 추가되면 이 메서드를 그걸로 교체하세요.
  Future<UserProfile> findMyProfile(String loginId) async {
    final list = await _client.get('/guardians') as List<dynamic>;
    final mine = list.cast<Map<String, dynamic>>().firstWhere(
          (g) => g['loginId'] == loginId,
          orElse: () => throw ApiException(404, '내 계정 정보를 찾을 수 없습니다.'),
        );
    return _fromJson(mine);
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