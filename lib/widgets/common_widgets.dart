import 'package:flutter/material.dart';

class HyopeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const HyopeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionTitle({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              color: Color(0xFF182033),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF4F80FF).withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF4F80FF)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF182033),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF7A8294),
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF4F80FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF263044),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    color: Color(0xFF7A8294),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class SettingsInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const SettingsInfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F5FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF687085)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF687085),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF263044),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
