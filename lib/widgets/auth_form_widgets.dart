import 'package:flutter/material.dart';

InputDecoration authInputDecoration({required String hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9AA2B4)),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE5E9F2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF4F80FF), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
  );
}

class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const LabeledField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF182033),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class AuthChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AuthChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF0FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF4F80FF) : const Color(0xFFE5E9F2),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFF4F80FF) : const Color(0xFF7A8294),
          ),
        ),
      ),
    );
  }
}