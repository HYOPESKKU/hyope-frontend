import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/hyope_models.dart';
import 'main_screen.dart';

class RecipientListScreen extends StatefulWidget {
  const RecipientListScreen({super.key});

  @override
  State<RecipientListScreen> createState() => _RecipientListScreenState();
}

class _RecipientListScreenState extends State<RecipientListScreen> {
  late final List<RecipientSummary> recipients;
  late UserProfile socialWorkerProfile;

  @override
  void initState() {
    super.initState();
    recipients = List<RecipientSummary>.from(MockData.managedRecipients);
    socialWorkerProfile = MockData.socialWorkerProfile;
  }

  void _updateRecipient(RecipientSummary updated) {
    final index = recipients.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;

    setState(() => recipients[index] = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '관리 피보호자',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: recipients.length + 1,
              separatorBuilder: (_, index) => index == 0
                  ? const SizedBox(height: 16)
                  : const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _ListHeader(count: recipients.length);
                }
                return _RecipientCard(
                  recipient: recipients[index - 1],
                  userProfile: socialWorkerProfile,
                  onUserProfileChanged: (updated) {
                    setState(() => socialWorkerProfile = updated);
                  },
                  onRecipientChanged: _updateRecipient,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  final int count;

  const _ListHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F80FF), Color(0xFF6D7CFF)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.groups_2_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '담당 대상자',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '현재 $count명을 관리하고 있습니다.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.86),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  final RecipientSummary recipient;
  final UserProfile userProfile;
  final ValueChanged<UserProfile> onUserProfileChanged;
  final ValueChanged<RecipientSummary> onRecipientChanged;

  const _RecipientCard({
    required this.recipient,
    required this.userProfile,
    required this.onUserProfileChanged,
    required this.onRecipientChanged,
  });

  @override
  Widget build(BuildContext context) {
    final latestAssessment =
        MockData.last30Days(recipientId: recipient.id).last;
    final level = latestAssessment.riskLevel;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MainScreen(
                userRole: AppUserRole.socialWorker,
                userProfile: userProfile,
                recipient: recipient,
                onUserProfileChanged: onUserProfileChanged,
                onRecipientChanged: onRecipientChanged,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  recipient.initial,
                  style: const TextStyle(
                    color: Color(0xFF4F80FF),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipient.name,
                      style: const TextStyle(
                        color: Color(0xFF182033),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '만 ${recipient.age}세 · ${recipient.gender.label}',
                      style: const TextStyle(
                        color: Color(0xFF7A8294),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: level.color.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  level.label,
                  style: TextStyle(
                    color: level.color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9AA2B4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
