import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import '../services/call_log_service.dart';

class ConversationDetailScreen extends StatefulWidget {
  final ConversationLog log;

  const ConversationDetailScreen({super.key, required this.log});

  @override
  State<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  late final Future<List<ConversationMessage>> _future;

  @override
  void initState() {
    super.initState();
    _future = CallLogService().findEntries(widget.log.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상담 내역 상세'),
        backgroundColor: const Color(0xFFF5F7FB),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: FutureBuilder<List<ConversationMessage>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('대화 내용을 불러오지 못했습니다.'));
                }

                final entries = snapshot.data ?? [];
                if (entries.isEmpty) {
                  return const Center(child: Text('대화 기록이 없습니다.'));
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF1F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${widget.log.status.label} · 총 ${entries.length}개 질문',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 20),
                    for (final entry in entries) ...[
                      _MessageBubble(text: entry.question, isAi: true),
                      _MessageBubble(text: entry.answer, isAi: false),
                      const SizedBox(height: 10),
                    ],
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

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isAi;

  const _MessageBubble({required this.text, required this.isAi});

  @override
  Widget build(BuildContext context) {
    // 통화가 끊기거나 어르신이 답을 안 하면 answer가 빈 문자열로 온다
    // (ConversationMessage.fromJson의 `?? ''`). 그대로 두면 속이 빈 파란
    // 말풍선이 떠서, 보호자는 답을 안 하신 건지 앱이 잘못된 건지 구분할 수
    // 없다. 무응답임을 글로 밝힌다.
    final isMissing = text.trim().isEmpty;
    final label = isMissing ? (isAi ? '(질문 없음)' : '(응답 없음)') : text;

    final background = isMissing
        ? const Color(0xFFF2F4F8)
        : (isAi ? const Color(0xFFEFF1F6) : const Color(0xFF4F80FF));
    final foreground = isMissing
        ? const Color(0xFF9AA2B4)
        : (isAi ? Colors.black87 : Colors.white);

    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border:
              isMissing ? Border.all(color: const Color(0xFFDDE2EC)) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }
}