import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/hyope_models.dart';
import 'api_client.dart';

const _kNotificationChannelId = 'guardian_notifications';
const _kNotificationChannelName = '보호 알림';
const _kNotificationChannelDescription = '통화 종료, 리포트 도착 등 보호 관련 알림';

/// 서버가 알림을 만들 때마다 /ws/notifications로 즉시 밀어주는 걸 받아서
/// 로컬 알림(OS 알림)으로 띄운다. 앱 프로세스가 살아있는 동안만 동작한다 —
/// 앱을 완전히 종료하면 소켓도 끊기고 다시 안 온다 (그건 FCM 영역).
class NotificationSocketService {
  NotificationSocketService._();
  static final NotificationSocketService instance = NotificationSocketService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _pluginReady = false;
  int _notificationSeq = 0;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  bool _shouldConnect = false;
  int _reconnectAttempt = 0;

  void connect() {
    if (_shouldConnect) return;
    _shouldConnect = true;
    _reconnectAttempt = 0;
    _open();
  }

  void disconnect() {
    _shouldConnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// 앱이 백그라운드에서 돌아왔을 때 호출. 소켓이 끊겨 있으면 백오프를
  /// 기다리지 않고 바로 재연결을 시도한다.
  void notifyAppResumed() {
    if (!_shouldConnect || _channel != null) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt = 0;
    _open();
  }

  Future<void> _ensurePluginInitialized() async {
    if (_pluginReady) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _kNotificationChannelId,
        _kNotificationChannelName,
        description: _kNotificationChannelDescription,
        importance: Importance.high,
      ),
    );
    _pluginReady = true;
  }

  Future<void> _open() async {
    final token = AuthSession.instance.token;
    if (!_shouldConnect || token == null) return;
    await _ensurePluginInitialized();
    if (!_shouldConnect) return;

    final wsBase = kApiBaseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final uri = Uri.parse('$wsBase/ws/notifications');

    try {
      final channel = IOWebSocketChannel.connect(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      _channel = channel;
      _reconnectAttempt = 0;
      _subscription = channel.stream.listen(
        _handleMessage,
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final notification = GuardianNotification.fromJson(json);
      _showLocalNotification(notification);
    } catch (_) {
      // 알 수 없는 형식의 메시지는 무시.
    }
  }

  Future<void> _showLocalNotification(GuardianNotification notification) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kNotificationChannelId,
        _kNotificationChannelName,
        channelDescription: _kNotificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      _notificationSeq++,
      _titleFor(notification.type),
      notification.message,
      details,
    );
  }

  String _titleFor(NotificationCategory type) {
    switch (type) {
      case NotificationCategory.callMissed:
        return '통화를 놓쳤어요';
      case NotificationCategory.callFailed:
        return '통화 연결에 실패했어요';
      case NotificationCategory.highRisk:
      case NotificationCategory.suddenSpike:
        return '위험 신호가 감지됐어요';
      case NotificationCategory.incompleteAnalysis:
        return '분석이 완료되지 않았어요';
      case NotificationCategory.newReport:
        return '새 리포트가 도착했어요';
      case NotificationCategory.dailyCallMissing:
        return '오늘 통화가 아직 없어요';
      case NotificationCategory.emergency:
        return '긴급 알림';
    }
  }

  void _scheduleReconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    if (!_shouldConnect) return;

    _reconnectAttempt++;
    final delaySeconds = _reconnectAttempt.clamp(1, 6) * 5; // 5, 10, ... 30초 상한
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), _open);
  }
}