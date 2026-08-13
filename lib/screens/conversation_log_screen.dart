import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import '../services/assessment_service.dart';
import '../services/call_log_service.dart';
import '../utils/date_utils.dart';
import 'conversation_detail_screen.dart';

class ConversationLogScreen extends StatefulWidget {
  final int recipientId;

  const ConversationLogScreen({super.key, required this.recipientId});

  @override
  State<ConversationLogScreen> createState() => _ConversationLogScreenState();
}

class _ConversationLogScreenState extends State<ConversationLogScreen> {
  late Future<_ConversationLogData> _future;

  /// 지금 보고 있는 주의 월요일. null이면 아직 로딩 전이라 정하지 못한 상태다.
  ///
  /// 첫 진입 시 "가장 최근 통화가 있는 주"로 맞춘다. 이번 주로 고정하면 며칠
  /// 통화가 없었을 때 빈 화면부터 보게 되고, 보호자는 기록이 사라진 줄 안다.
  DateTime? _weekStart;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ConversationLogData> _load() async {
    final logs = await CallLogService().findByRecipient(widget.recipientId);
    final assessments = await AssessmentService().findByRecipient(widget.recipientId);

    // callLogId 기준으로 요약(summary)을 매칭할 수 있도록 맵으로 변환
    final summaryByCallLogId = <int, String>{
      for (final a in assessments) a.callLogId: a.summary,
    };

    return _ConversationLogData(logs: logs, summaryByCallLogId: summaryByCallLogId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
      _weekStart = null;   // 새로 받은 목록 기준으로 다시 정한다
    });
    await _future;
  }

  void _moveWeek(int weeks) {
    final current = _weekStart;
    if (current == null) return;
    setState(() => _weekStart = current.add(Duration(days: 7 * weeks)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: RefreshIndicator(
            onRefresh: _reload,
            child: FutureBuilder<_ConversationLogData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return ListView(
                    children: [
                      const SizedBox(height: 80),
                      const Icon(Icons.error_outline, size: 40, color: Color(0xFF9AA2B4)),
                      const SizedBox(height: 12),
                      const Center(child: Text('상담 내역을 불러오지 못했습니다.')),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(onPressed: _reload, child: const Text('다시 시도')),
                      ),
                    ],
                  );
                }

                final data = snapshot.data!;
                final all = [...data.logs]
                  ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

                // 기록이 아예 없으면 주 이동 자체가 의미 없다.
                if (all.isEmpty) {
                  return ListView(
                    children: const [
                      _ScreenTitle(),
                      Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('아직 상담 기록이 없습니다.'),
                      ),
                    ],
                  );
                }

                // 첫 프레임에서 확정. all이 최신순이라 first가 가장 최근 통화다.
                final weekStart = _weekStart ??= startOfWeek(all.first.startedAt);

                final logs = all
                    .where((log) => isInWeek(log.startedAt, weekStart))
                    .toList();

                // 이동 한계. 기록이 있는 범위 밖으로는 못 나가게 막는다 —
                // 빈 주를 무한히 넘기게 두면 끝이 어딘지 알 수 없다.
                final oldestWeek = startOfWeek(all.last.startedAt);
                final newestWeek = startOfWeek(all.first.startedAt);
                final thisWeek = startOfWeek(DateTime.now());
                // 이번 주는 아직 통화가 없어도 볼 수 있어야 한다(오늘 걸 기다리는 중).
                final maxWeek = newestWeek.isAfter(thisWeek) ? newestWeek : thisWeek;

                return CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: _ScreenTitle()),
                    SliverToBoxAdapter(
                      child: _WeekNavigator(
                        weekStart: weekStart,
                        onPrevious: weekStart.isAfter(oldestWeek)
                            ? () => _moveWeek(-1)
                            : null,
                        onNext:
                            weekStart.isBefore(maxWeek) ? () => _moveWeek(1) : null,
                      ),
                    ),
                    if (logs.isEmpty)
                      const SliverToBoxAdapter(child: _EmptyWeek())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _ConversationLogTile(
                              log: logs[index],
                              summary: data.summaryByCallLogId[logs[index].id],
                            ),
                            childCount: logs.length,
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationLogData {
  final List<ConversationLog> logs;
  final Map<int, String> summaryByCallLogId;

  const _ConversationLogData({required this.logs, required this.summaryByCallLogId});
}

class _ScreenTitle extends StatelessWidget {
  const _ScreenTitle();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        '상담 대화내역',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// 주 단위 이동 막대.
///
/// 콜백이 null이면 그 방향 끝이라는 뜻이고 버튼이 흐려진다. 버튼을 숨기지 않고
/// 비활성으로 두는 이유는, 사라지면 자리가 밀려서 연타할 때 다른 곳을 누르게
/// 되기 때문이다.
class _WeekNavigator extends StatelessWidget {
  final DateTime weekStart;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _WeekNavigator({
    required this.weekStart,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6EAF2)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
              tooltip: '이전 주',
              color: const Color(0xFF4F80FF),
            ),
            Expanded(
              child: Text(
                formatWeekRange(weekStart),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF182033),
                ),
              ),
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
              tooltip: '다음 주',
              color: const Color(0xFF4F80FF),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWeek extends StatelessWidget {
  const _EmptyWeek();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        children: [
          Icon(Icons.event_busy_outlined, size: 38, color: Color(0xFF9AA2B4)),
          SizedBox(height: 12),
          Text(
            '이 주에는 대화내역이 없습니다.',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF687085),
            ),
          ),
          SizedBox(height: 6),
          Text(
            '좌우 화살표로 다른 주를 확인해 보세요.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF9AA2B4)),
          ),
        ],
      ),
    );
  }
}

class _ConversationLogTile extends StatelessWidget {
  final ConversationLog log;
  final String? summary;

  const _ConversationLogTile({required this.log, required this.summary});

  String get _dateLabel {
    final d = log.startedAt;
    return '${d.month}월 ${d.day}일 ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String get _durationLabel {
    final m = log.durationSec ~/ 60;
    final s = log.durationSec % 60;
    return '${m}분 ${s}초';
  }

  @override
  Widget build(BuildContext context) {
    final hasSummary = summary != null && summary!.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE7EAF2)),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ConversationDetailScreen(log: log)),
          );
        },
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEFF1F6),
          child: Icon(Icons.call_outlined, color: Color(0xFF4F80FF)),
        ),
        title: Text(_dateLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${log.status.label} · $_durationLabel',
              style: const TextStyle(fontSize: 12, color: Color(0xFF9AA2B4)),
            ),
            const SizedBox(height: 2),
            Text(
              hasSummary ? summary! : '요약이 아직 준비되지 않았습니다.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasSummary ? const Color(0xFF404A5C) : const Color(0xFF9AA2B4),
                fontStyle: hasSummary ? FontStyle.normal : FontStyle.italic,
                height: 1.35,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}