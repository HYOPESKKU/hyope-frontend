import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import '../services/assessment_service.dart';
import '../services/call_log_service.dart';
import 'conversation_detail_screen.dart';

class ConversationLogScreen extends StatefulWidget {
  final int recipientId;

  const ConversationLogScreen({super.key, required this.recipientId});

  @override
  State<ConversationLogScreen> createState() => _ConversationLogScreenState();
}

class _ConversationLogScreenState extends State<ConversationLogScreen> {
  late Future<_ConversationLogData> _future;

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
    });
    await _future;
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
                final logs = [...data.logs]
                  ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

                return CustomScrollView(
                  slivers: [
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          '상담 대화내역',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    if (logs.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('아직 상담 기록이 없습니다.'),
                        ),
                      )
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