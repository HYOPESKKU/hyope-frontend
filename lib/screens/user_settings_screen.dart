import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/common_widgets.dart';

class UserSettingsScreen extends StatelessWidget {
  final bool biometricLockEnabled;
  final bool darkModeEnabled;
  final ValueChanged<bool> onBiometricLockChanged;
  final ValueChanged<bool> onDarkModeChanged;

  const UserSettingsScreen({
    super.key,
    required this.biometricLockEnabled,
    required this.darkModeEnabled,
    required this.onBiometricLockChanged,
    required this.onDarkModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              const PageHeader(
                title: '사용자 설정',
                subtitle: '보호자와 피보호자 정보를 확인하고 앱 환경을 조정합니다.',
                icon: Icons.manage_accounts_outlined,
              ),
              const SizedBox(height: 14),
              HyopeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(title: '피보호자 정보'),
                    const SizedBox(height: 10),
                    SettingsInfoRow(
                      icon: Icons.person_outline,
                      title: '이름',
                      value: MockData.recipient.name,
                    ),
                    SettingsInfoRow(
                      icon: Icons.group_outlined,
                      title: '관계',
                      value: MockData.recipient.relation,
                    ),
                    SettingsInfoRow(
                      icon: Icons.call_outlined,
                      title: '연락처',
                      value: MockData.recipient.phoneNumber,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              HyopeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
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
