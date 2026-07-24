import '../models/hyope_models.dart';
import 'api_client.dart';

class CallLogService {
  final _client = ApiClient();

  Future<List<ConversationLog>> findByRecipient(int recipientId) async {
    final result =
        await _client.get('/recipients/$recipientId/call-logs') as Map<String, dynamic>;

    final content = (result['content'] as List<dynamic>).cast<Map<String, dynamic>>();
    final logs = content.map((json) => ConversationLog.fromJson(json)).toList();

    logs.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return logs;
  }

  Future<List<ConversationMessage>> findEntries(int callLogId) async {
    final result = await _client.get('/call-logs/$callLogId/call-log-entries')
        as Map<String, dynamic>;

    final content = (result['content'] as List<dynamic>).cast<Map<String, dynamic>>();
    final entries = content.map((json) => ConversationMessage.fromJson(json)).toList();

    entries.sort((a, b) => a.sequence.compareTo(b.sequence));
    return entries;
  }
}