import '../config/dev_flags.dart';
import '../data/mock_data.dart';
import '../models/hyope_models.dart';
import 'api_client.dart';

class AssessmentService {
  final _client = ApiClient();

  Future<List<DailyAssessment>> findByRecipient(int recipientId) async {
    // 목 모드 — 백엔드에 테스트 데이터를 넣지 않고 화면을 확인할 때 쓴다.
    // 팀 DB는 공유 자원이라 임의로 더미를 넣으면 다른 사람 작업과 엉킨다.
    // flutter run --dart-define=USE_MOCK=true
    if (kUseMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return kMockFailCases
          ? MockData.withFailCases(recipientId: recipientId)
          : MockData.last30Days(recipientId: recipientId);
    }

    List<dynamic> rawList;
    try {
      final response =
          await _client.get('/recipients/$recipientId/assessments');
      rawList = response is List<dynamic> ? response : <dynamic>[];
    } on ApiException catch (e) {
      // 분석 기록이 없는 대상자는 404 등을 반환할 수 있으므로 빈 목록으로 처리
      if (e.statusCode == 404) {
        return <DailyAssessment>[];
      }
      rethrow;
    }

    if (rawList.isEmpty) return <DailyAssessment>[];

    final assessmentJsonList = rawList
        .whereType<Map>()
        .map((json) => Map<String, dynamic>.from(json))
        .toList();

    // Assessment 목록 응답에는 이행 기록이 포함되지 않으므로,
    // 각 assessment id로 복약/식사 기록을 추가 조회해 합친다.
    final assessments = await Future.wait(
      assessmentJsonList.map((assessmentJson) async {
        final assessmentId = _toAssessmentId(assessmentJson['id']);
        final adherenceJsonList = assessmentId == null
            ? <dynamic>[]
            : await _client.get(
                  '/assessments/$assessmentId/adherence-records',
                )
                as List<dynamic>;

        return DailyAssessment.fromJson({
          ...assessmentJson,
          'recipientId': recipientId,
          'adherenceRecords': adherenceJsonList,
        });
      }),
    );

    assessments.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    return assessments;
  }

  int? _toAssessmentId(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}