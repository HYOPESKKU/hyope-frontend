import '../models/hyope_models.dart';
import 'api_client.dart';

class RecipientService {
  final _client = ApiClient();

  Future<List<RecipientSummary>> findByGuardian(int guardianId) async {
    final list =
        await _client.get('/guardians/$guardianId/recipients') as List<dynamic>;
    return list.cast<Map<String, dynamic>>().map(_fromJson).toList();
  }

  Future<RecipientSummary> createRecipient({
    required int guardianId,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required Gender gender,
    required String relationToGuardian,
    required String phoneNumber,
  }) async {
    final json = await _client.post(
      '/guardians/$guardianId/recipients',
      body: {
        'guardian_id': guardianId,
        'firstName': firstName,
        'lastName': lastName,
        'birthDate': birthDate.toIso8601String().split('T').first,
        'gender': gender == Gender.male ? 'MALE' : 'FEMALE',
        'relationToGuardian': relationToGuardian,
        'phoneNumber': phoneNumber,
      },
    ) as Map<String, dynamic>;
    return _fromJson(json);
  }

  Future<RecipientSummary> updateRecipient({
    required int id,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required Gender gender,
    required String relationToGuardian, // 백엔드 RelationType 문자열, 예: 'PARENT'
    required String phoneNumber,
  }) async {
    final json = await _client.patch(
      '/recipients/$id',
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'birthDate': birthDate.toIso8601String().split('T').first,
        'gender': gender == Gender.male ? 'MALE' : 'FEMALE',
        'relationToGuardian': relationToGuardian,
        'phoneNumber': phoneNumber,
      },
    ) as Map<String, dynamic>;
    return _fromJson(json);
  }

  RecipientSummary _fromJson(Map<String, dynamic> json) {
    return RecipientSummary(
      id: json['id'] as int,
      name: '${json['lastName']}${json['firstName']}',
      birthDate: DateTime.parse(json['birthDate'] as String),
      gender: (json['gender'] as String) == 'MALE' ? Gender.male : Gender.female,
      relation: relationLabel(json['relationToGuardian'] as String),
      phoneNumber: json['phoneNumber'] as String,
    );
  }

  String relationLabel(String relationType) {
    switch (relationType) {
      case 'CHILD':
        return '자녀';
      case 'PARENT':
        return '부모';
      case 'SPOUSE':
        return '배우자';
      case 'SIBLING':
        return '형제/자매';
      case 'CAREGIVER':
        return '간병인';
      case 'ADMIN':
        return '담당 피보호자';
      default:
        return '기타';
    }
  }
}