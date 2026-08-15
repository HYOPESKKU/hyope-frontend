import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/hyope_models.dart';

/// 통화로 자동 갱신되는 항목이 마지막으로 본 뒤 바뀌었는지 기억한다.
///
/// 취미와 최근 근황은 보호자가 입력하지 않는다. 통화 중 AI가 알아낸 내용을
/// 서버가 채운다(brain.py의 update_recipient_profile). 그래서 앱을 다시 열었을
/// 때 조용히 값만 바뀌어 있고, 보호자는 무엇이 새로 생겼는지 알 수 없다.
///
/// 서버가 갱신 시각을 주지 않아 "지난번에 본 값"을 기기에 저장해 두고 비교한다.
/// 서버가 나중에 updatedAt이나 알림을 제공하면 그쪽으로 옮기는 편이 낫다 —
/// 기기에만 있으면 폰을 바꾸거나 다른 기기로 로그인했을 때 표시가 초기화된다.
class ProfileSeenStore {
  static const _keyPrefix = 'seen_profile_';

  /// 바뀐 항목 이름. RecipientInfoCard가 이 값으로 배지를 띄운다.
  static const fieldHobbies = 'hobbies';
  static const fieldRecentEvents = 'recentEvents';

  String _key(int recipientId) => '$_keyPrefix$recipientId';

  /// 지난번에 본 값과 달라진 항목을 돌려준다.
  ///
  /// 처음 보는 피보호자면 비교 대상이 없다. 이때 전부 "업데이트"로 띄우면 첫
  /// 화면이 배지투성이가 되므로, 조용히 현재 값을 기록하고 빈 집합을 준다.
  Future<Set<String>> updatedFields(RecipientSummary recipient) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(recipient.id));

    if (raw == null) {
      await markSeen(recipient);
      return const {};
    }

    final Map<String, dynamic> saved;
    try {
      saved = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      // 저장 형식이 바뀌었거나 깨진 경우. 새로 기록하고 넘어간다.
      await markSeen(recipient);
      return const {};
    }

    final changed = <String>{};
    if (!_sameItems(saved[fieldHobbies], recipient.hobbies)) {
      changed.add(fieldHobbies);
    }
    if (!_sameItems(saved[fieldRecentEvents], recipient.recentEvents)) {
      changed.add(fieldRecentEvents);
    }
    return changed;
  }

  /// 현재 값을 "본 것"으로 기록한다.
  Future<void> markSeen(RecipientSummary recipient) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(recipient.id),
      jsonEncode({
        fieldHobbies: recipient.hobbies,
        fieldRecentEvents: recipient.recentEvents,
      }),
    );
  }

  /// 피보호자를 삭제했을 때 남은 기록을 지운다.
  Future<void> clear(int recipientId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(recipientId));
  }

  /// 순서는 무시하고 내용만 비교한다.
  ///
  /// 서버가 같은 항목을 다른 순서로 돌려주는 것만으로 "업데이트"가 뜨면
  /// 배지를 믿을 수 없게 된다.
  bool _sameItems(dynamic saved, List<String> current) {
    if (saved is! List) return current.isEmpty;
    return Set<String>.from(saved.map((e) => e.toString())) ==
        current.toSet();
  }
}
