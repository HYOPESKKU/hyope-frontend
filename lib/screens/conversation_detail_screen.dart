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
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isAi ? const Color(0xFFEFF1F6) : const Color(0xFF4F80FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(color: isAi ? Colors.black87 : Colors.white),
        ),
      ),
    );
  }
}