import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import 'login_screen.dart';

/// 앱 진입 시 역할을 먼저 고르고, 그 역할로 로그인 화면으로 이동합니다.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F80FF),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.volunteer_activism_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'HYOPE',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF182033),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '어떤 역할로 이용하시나요? 선택 후 로그인해주세요.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: Color(0xFF7A8294),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _RoleCard(
                    icon: Icons.family_restroom_rounded,
                    title: '보호자로 시작',
                    description: '로그인 후 연결된 피보호자의 대시보드로 바로 이동합니다.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginScreen(
                            selectedRole: AppUserRole.guardian,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _RoleCard(
                    icon: Icons.badge_outlined,
                    title: '복지사로 시작',
                    description: '관리 중인 피보호자 목록을 확인하고 대시보드를 선택합니다.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginScreen(
                            selectedRole: AppUserRole.socialWorker,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: const Color(0xFF4F80FF)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF182033),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: Color(0xFF7A8294),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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