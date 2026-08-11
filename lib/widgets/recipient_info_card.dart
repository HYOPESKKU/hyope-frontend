import 'package:flutter/material.dart';

import '../models/hyope_models.dart';

class RecipientInfoCard extends StatelessWidget {
  final RecipientSummary recipient;

  const RecipientInfoCard({
    super.key,
    required this.recipient,
  });

  @override
  Widget build(BuildContext context) {
    final hasAddress =
        recipient.address != null && recipient.address!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '돌봄 대상자 정보',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF182033),
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: '주소',
            child: hasAddress
                ? Text(
                    recipient.address!,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF3A4257),
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : const _EmptyValueText(),
          ),
          _InfoRow(
            icon: Icons.palette_outlined,
            label: '취미',
            child: recipient.hobbies.isNotEmpty
                ? Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: recipient.hobbies
                        .map((hobby) => _Chip(text: hobby))
                        .toList(),
                  )
                : const _EmptyValueText(),
          ),
          _InfoRow(
            icon: Icons.event_note_outlined,
            label: '최근 근황',
            isLast: true,
            child: recipient.recentEvents.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: recipient.recentEvents
                        .map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '· $event',
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF3A4257),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  )
                : const _EmptyValueText(),
          ),
        ],
      ),
    );
  }
}

class _EmptyValueText extends StatelessWidget {
  const _EmptyValueText();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '없음',
      style: TextStyle(
        fontSize: 13.5,
        color: Color(0xFF9AA2B4),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.child,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF7A8294)),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7A8294),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;

  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4F80FF),
        ),
      ),
    );
  }
}