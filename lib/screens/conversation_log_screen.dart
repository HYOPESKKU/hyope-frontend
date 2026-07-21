import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import 'conversation_detail_screen.dart';

class ConversationLogScreen extends StatelessWidget {
  final List<ConversationLog> logs;

  const ConversationLogScreen({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final sorted = [...logs]..sort((a, b) => b.calledAt.compareTo(a.calledAt));

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: CustomScrollView(
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
              if (sorted.isEmpty)
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
                      (context, index) => _ConversationLogTile(log: sorted[index]),
                      childCount: sorted.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationLogTile extends StatelessWidget {
  final ConversationLog log;

  const _ConversationLogTile({required this.log});

  String get _dateLabel {
    final d = log.calledAt;
    return '${d.month}월 ${d.day}일 ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
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
        subtitle: Text(
          log.summary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}