import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import '../services/profile_seen_store.dart';

class RecipientInfoCard extends StatelessWidget {
  final RecipientSummary recipient;

  /// 마지막으로 본 뒤 통화로 바뀐 항목들(ProfileSeenStore.field* 값).
  ///
  /// 취미·최근 근황은 보호자가 입력하지 않고 통화 중 AI가 채운다. 표시가
  /// 없으면 값이 조용히 바뀌어 있어 무엇이 새로 생겼는지 알 수 없다.
  final Set<String> updatedFields;

  /// 배지를 눌러 "확인함"으로 표시할 때. null이면 배지를 눌러도 반응하지 않는다.
  final VoidCallback? onAcknowledgeUpdates;

  const RecipientInfoCard({
    super.key,
    required this.recipient,
    this.updatedFields = const {},
    this.onAcknowledgeUpdates,
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
            isUpdated: updatedFields.contains(ProfileSeenStore.fieldHobbies),
            onAcknowledge: onAcknowledgeUpdates,
            child: recipient.hobbies.isNotEmpty
                ? Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: recipient.hobbies
                        .map((hobby) => _Chip(text: hobby))
                        .toList(),
                  )
                : const _EmptyValueText(hint: '통화 중 알게 되면 자동으로 채워져요'),
          ),
          _InfoRow(
            icon: Icons.event_note_outlined,
            label: '최근 근황',
            isLast: true,
            isUpdated:
                updatedFields.contains(ProfileSeenStore.fieldRecentEvents),
            onAcknowledge: onAcknowledgeUpdates,
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
                : const _EmptyValueText(hint: '통화 중 알게 되면 자동으로 채워져요'),
          ),
        ],
      ),
    );
  }
}

class _EmptyValueText extends StatelessWidget {
  /// 값이 없는 이유를 덧붙일 때 쓴다.
  ///
  /// 취미·최근 근황은 보호자가 입력하는 값이 아니라 통화 중 AI가 수집한다
  /// (백엔드 RecipientProfileService.applyUpdates는 통화 결과로만 호출된다).
  /// 그냥 "없음"만 보이면 보호자가 입력란을 찾다가 못 찾는다.
  final String? hint;

  const _EmptyValueText({this.hint});

  @override
  Widget build(BuildContext context) {
    const emptyStyle = TextStyle(
      fontSize: 13.5,
      color: Color(0xFF9AA2B4),
      fontWeight: FontWeight.w500,
    );

    if (hint == null) return const Text('없음', style: emptyStyle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('없음', style: emptyStyle),
        const SizedBox(height: 2),
        Text(
          hint!,
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFFB0B7C5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  final bool isLast;
  final bool isUpdated;
  final VoidCallback? onAcknowledge;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.child,
    this.isLast = false,
    this.isUpdated = false,
    this.onAcknowledge,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isUpdated) ...[
                  _UpdatedBadge(onTap: onAcknowledge),
                  const SizedBox(height: 5),
                ],
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "통화로 새로 채워졌다"는 표시.
///
/// 눌러서 없앨 수 있게 한 이유는, 화면을 열자마자 사라지면 스크롤로 지나쳤을 때
/// 다시 볼 방법이 없기 때문이다. 보호자가 직접 확인했다고 눌러야 사라진다.
class _UpdatedBadge extends StatelessWidget {
  final VoidCallback? onTap;

  const _UpdatedBadge({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF4F80FF).withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 12, color: Color(0xFF4F80FF)),
            const SizedBox(width: 4),
            const Text(
              '통화로 업데이트됨',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4F80FF),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.close, size: 12, color: Color(0xFF4F80FF)),
            ],
          ],
        ),
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