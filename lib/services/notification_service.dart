import '../models/hyope_models.dart';
import 'api_client.dart';

class NotificationService {
  final _client = ApiClient();

  Future<List<GuardianNotification>> fetchMine() async {
    final list = await _client.get('/notifications') as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(GuardianNotification.fromJson)
        .toList();
  }

  Future<void> markRead(int id) async {
    await _client.patch('/notifications/$id/read');
  }

  Future<void> delete(int id) async {
    await _client.delete('/notifications/$id');
  }
}