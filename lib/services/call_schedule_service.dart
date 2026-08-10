import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import 'api_client.dart';

class CallScheduleService {
  final _client = ApiClient();

  Future<CallSchedule> read(int id) async {
    final json = await _client.get('/call-schedules/$id') as Map<String, dynamic>;
    return CallSchedule.fromJson(json);
  }

  Future<List<CallSchedule>> findByRecipient(int recipientId) async {
    final list = await _client.get('/recipients/$recipientId/call-schedules')
        as List<dynamic>;
    return list.cast<Map<String, dynamic>>().map(CallSchedule.fromJson).toList();
  }

  Future<CallSchedule> create({
    required int recipientId,
    required TimeOfDay scheduledTime,
    int? intervalDays,
    bool isActive = true,
  }) async {
    final json = await _client.post(
      '/recipients/$recipientId/call-schedules',
      body: {
        'recipient_id': recipientId,
        'scheduledTime': formatTimeOfDayForApi(scheduledTime),
        'intervalDays': intervalDays,
        'isActive': isActive,
      },
    ) as Map<String, dynamic>;
    return CallSchedule.fromJson(json);
  }

  Future<CallSchedule> update({
    required int id,
    required int recipientId,
    required TimeOfDay scheduledTime,
    int? intervalDays,
    bool isActive = true,
  }) async {
    final json = await _client.patch(
      '/call-schedules/$id',
      body: {
        'recipient_id': recipientId,
        'scheduledTime': formatTimeOfDayForApi(scheduledTime),
        'intervalDays': intervalDays,
        'isActive': isActive,
      },
    ) as Map<String, dynamic>;
    return CallSchedule.fromJson(json);
  }

  Future<void> delete(int id) async {
    await _client.delete('/call-schedules/$id');
  }
}
