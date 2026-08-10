import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import '../widgets/common_widgets.dart';

class UserSettingsScreen extends StatelessWidget {
  final AppUserRole userRole;
  final UserProfile userProfile;
  final RecipientSummary recipient;
  final bool biometricLockEnabled;
  final bool darkModeEnabled;
  final VoidCallback onEditUserProfile;
  final VoidCallback onEditRecipient;
  final ValueChanged<bool> onBiometricLockChanged;
  final ValueChanged<bool> onDarkModeChanged;

  const UserSettingsScreen({
    super.key,
    required this.userRole,
    required this.userProfile,
    required this.recipient,
    required this.biometricLockEnabled,
    required this.darkModeEnabled,
    required this.onEditUserProfile,
    required this.onEditRecipient,
    required this.onBiometricLockChanged,
    required this.onDarkModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSocialWorker = userRole == AppUserRole.socialWorker;
    final userTitle = isSocialWorker ? '복지사 정보' : '보호자 정보';

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              PageHeader(
                title: '내 정보',
                subtitle: isSocialWorker
                    ? '복지사 본인과 선택한 피보호자 정보를 관리합니다.'
                    : '보호자와 피보호자 정보를 확인하고 수정합니다.',
                icon: Icons.manage_accounts_outlined,
              ),
              const SizedBox(height: 14),
              HyopeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(
                      title: userTitle,
                      trailing: _EditButton(onPressed: onEditUserProfile),
                    ),
                    const SizedBox(height: 10),
                    SettingsInfoRow(
                      icon: Icons.person_outline,
                      title: '이름',
                      value: userProfile.name,
                    ),
                    SettingsInfoRow(
                      icon: Icons.call_outlined,
                      title: '연락처',
                      value: userProfile.phoneNumber,
                    ),
                    SettingsInfoRow(
                      icon: Icons.email_outlined,
                      title: '이메일',
                      value: userProfile.email,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              HyopeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(
                      title: '피보호자 정보',
                      trailing: _EditButton(onPressed: onEditRecipient),
                    ),
                    const SizedBox(height: 10),
                    SettingsInfoRow(
                      icon: Icons.person_outline,
                      title: '이름',
                      value: recipient.name,
                    ),
                    SettingsInfoRow(
                      icon: Icons.cake_outlined,
                      title: '나이 / 성별',
                      value:
                          '만 ${recipient.age}세 / ${recipient.gender.label}',
                    ),
                    SettingsInfoRow(
                      icon: Icons.group_outlined,
                      title: isSocialWorker ? '관리 구분' : '관계',
                      value: recipient.relation,
                    ),
                    SettingsInfoRow(
                      icon: Icons.call_outlined,
                      title: '연락처',
                      value: recipient.phoneNumber,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const HyopeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(title: 'ARS 모니터링 설정'),
                    SizedBox(height: 10),
                    SettingsInfoRow(
                      icon: Icons.schedule_outlined,
                      title: '매일 전화 시간',
                      value: '오전 10:00',
                    ),
                    SettingsInfoRow(
                      icon: Icons.replay_outlined,
                      title: '무응답 재시도',
                      value: '2회',
                    ),
                    SettingsInfoRow(
                      icon: Icons.delete_outline,
                      title: '녹음 보관 기간',
                      value: '30일',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              HyopeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(title: '앱 환경'),
                    const SizedBox(height: 10),
                    SettingsSwitchTile(
                      icon: Icons.fingerprint_rounded,
                      title: '생체 인증 잠금',
                      subtitle: '앱 실행 시 지문 또는 얼굴 인증 사용',
                      value: biometricLockEnabled,
                      onChanged: onBiometricLockChanged,
                    ),
                    SettingsSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: '다크 모드',
                      subtitle: '어두운 배경의 앱 화면 사용',
                      value: darkModeEnabled,
                      onChanged: onDarkModeChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _EditButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.edit_outlined, size: 17),
      label: const Text('수정'),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}
