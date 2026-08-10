import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import '../services/assessment_service.dart';
import 'main_screen.dart';
import 'recipient_onboarding_screen.dart';

class RecipientListScreen extends StatefulWidget {
  final AppUserRole userRole;
  final UserProfile userProfile;
  final List<RecipientSummary> recipients;

  const RecipientListScreen({
    super.key,
    required this.userRole,
    required this.userProfile,
    required this.recipients,
  });

  @override
  State<RecipientListScreen> createState() => _RecipientListScreenState();
}

class _RecipientListScreenState extends State<RecipientListScreen> {
  late List<RecipientSummary> recipients;
  late UserProfile userProfile;

  @override
  void initState() {
    super.initState();
    recipients = List<RecipientSummary>.from(widget.recipients);
    userProfile = widget.userProfile;
  }

  void _updateRecipient(RecipientSummary updated) {
    final index = recipients.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;

    setState(() => recipients[index] = updated);
  }

  Future<void> _addRecipient() async {
    final created = await Navigator.of(context).push<RecipientSummary>(
      MaterialPageRoute<RecipientSummary>(
        builder: (_) => RecipientOnboardingScreen(guardianId: userProfile.id),
      ),
    );
    if (created == null || !mounted) return;

    setState(() => recipients = [...recipients, created]);
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
        child: recipients.isEmpty
            ? _EmptyState(onAdd: _addRecipient)
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    itemCount: recipients.length + 1,
                    separatorBuilder: (_, index) => index == 0
                        ? const SizedBox(height: 16)
                        : const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _ListHeader(count: recipients.length);
                      }
                      return _RecipientCard(
                        key: ValueKey(recipients[index - 1].id),
                        userRole: widget.userRole,
                        recipient: recipients[index - 1],
                        userProfile: userProfile,
                        onUserProfileChanged: (updated) {
                          setState(() => userProfile = updated);
                        },
                        onRecipientChanged: _updateRecipient,
                      );
                    },
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecipient,
        backgroundColor: const Color(0xFF4F80FF),
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text(
          '피보호자 등록',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.family_restroom_rounded,
                color: Color(0xFF4F80FF),
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '등록된 피보호자가 없습니다',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF182033),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '아래 버튼을 눌러 첫 피보호자를 등록해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFF7A8294),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('피보호자 등록'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F80FF),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
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
  final AppUserRole userRole;
  final RecipientSummary recipient;
  final UserProfile userProfile;
  final ValueChanged<UserProfile> onUserProfileChanged;
  final ValueChanged<RecipientSummary> onRecipientChanged;

  const _RecipientCard({
    super.key,
    required this.userRole,
    required this.recipient,
    required this.userProfile,
    required this.onUserProfileChanged,
    required this.onRecipientChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MainScreen(
                userRole: userRole,
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
              _RiskBadge(recipientId: recipient.id),
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

class _RiskBadge extends StatefulWidget {
  final int recipientId;

  const _RiskBadge({required this.recipientId});

  @override
  State<_RiskBadge> createState() => _RiskBadgeState();
}

class _RiskBadgeState extends State<_RiskBadge> {
  late final Future<List<DailyAssessment>> _future;

  @override
  void initState() {
    super.initState();
    _future = AssessmentService().findByRecipient(widget.recipientId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DailyAssessment>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final assessments = snapshot.data;
        if (assessments == null || assessments.isEmpty) {
          return const SizedBox.shrink();
        }

        final level = assessments.last.riskLevel;
        return Container(
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
        );
      },
    );
  }
}