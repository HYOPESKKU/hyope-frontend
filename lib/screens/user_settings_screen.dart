import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import '../widgets/common_widgets.dart';

class UserSettingsScreen extends StatelessWidget {
  final AppUserRole userRole;
  final UserProfile userProfile;
  final RecipientSummary recipient;
  final CallSchedule? callSchedule;
  final bool dailyNewsAlertEnabled;
  final bool riskChangeAlertEnabled;
  final bool emergencySmsEnabled;
  final VoidCallback onEditUserProfile;
  final VoidCallback onEditRecipient;
  final ValueChanged<bool> onDailyNewsAlertChanged;
  final ValueChanged<bool> onRiskChangeAlertChanged;
  final ValueChanged<bool> onEmergencySmsChanged;
  final VoidCallback onLogout;

  const UserSettingsScreen({
    super.key,
    required this.userRole,
    required this.userProfile,
    required this.recipient,
    required this.callSchedule,
    required this.dailyNewsAlertEnabled,
    required this.riskChangeAlertEnabled,
    required this.emergencySmsEnabled,
    required this.onEditUserProfile,
    required this.onEditRecipient,
    required this.onDailyNewsAlertChanged,
    required this.onRiskChangeAlertChanged,
    required this.onEmergencySmsChanged,
    required this.onLogout,
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
              HyopeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(
                      title: 'ARS 모니터링 설정',
                      trailing: _EditButton(onPressed: onEditRecipient),
                    ),
                    const SizedBox(height: 10),
                    SettingsInfoRow(
                      icon: Icons.schedule_outlined,
                      title: '전화 예약 시간',
                      value: callSchedule == null
                          ? '설정되지 않음'
                          : formatTimeOfDayKo(callSchedule!.scheduledTime),
                    ),
                    SettingsInfoRow(
                      icon: Icons.repeat_rounded,
                      title: '반복 간격',
                      value: callSchedule == null
                          ? '-'
                          : '${callSchedule!.intervalDays ?? 1}일마다',
                    ),
                    const SettingsInfoRow(
                      icon: Icons.replay_outlined,
                      title: '무응답 재시도',
                      value: '2회',
                    ),
                    const SettingsInfoRow(
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
                    const SectionTitle(title: '알림 설정'),
                    const SizedBox(height: 10),
                    SettingsSwitchTile(
                      icon: Icons.description_outlined,
                      title: '오늘의 소식 알림',
                      subtitle: '리포트 도착, 통화 미완료, 전화 무응답 알림',
                      value: dailyNewsAlertEnabled,
                      onChanged: onDailyNewsAlertChanged,
                    ),
                    SettingsSwitchTile(
                      icon: Icons.trending_up_rounded,
                      title: '위험도 변동 알림',
                      subtitle: '위험도 기준 초과, 급격한 변동 시 알림',
                      value: riskChangeAlertEnabled,
                      onChanged: onRiskChangeAlertChanged,
                    ),
                    SettingsSwitchTile(
                      icon: Icons.emergency_outlined,
                      title: '위급상황 SMS 알림',
                      subtitle: '응급 상황 감지 시 앱과 문자로 즉시 알림',
                      value: emergencySmsEnabled,
                      onChanged: onEmergencySmsChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('로그아웃'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE5484D),
                    side: const BorderSide(color: Color(0xFFE5484D)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
