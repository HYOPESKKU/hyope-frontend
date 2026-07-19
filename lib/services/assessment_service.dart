import '../models/hyope_models.dart';
import 'api_client.dart';

class AssessmentService {
  final _client = ApiClient();

  /// TODO: 백엔드 AssessmentResponse에 id가 없어서, 개별 assessment의
  /// 복약/식사 이행 기록(GET /assessments/{id}/adherence-records)은 아직 연결할 수 없습니다.
  /// 백엔드에 id 필드가 추가되면 여기서 함께 채워주세요.
  Future<List<DailyAssessment>> findByRecipient(int recipientId) async {
    final list = await _client.get('/recipients/$recipientId/assessments')
        as List<dynamic>;

    final assessments = list
        .cast<Map<String, dynamic>>()
        .map((json) => DailyAssessment.fromJson({
              ...json,
              'recipientId': recipientId,
            }))
        .toList();

    assessments.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    return assessments;
  }
}