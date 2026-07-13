import 'package:flutter/material.dart';

import '../models/hyope_models.dart';

class EditRecipientScreen extends StatefulWidget {
  final RecipientSummary recipient;
  final AppUserRole userRole;

  const EditRecipientScreen({
    super.key,
    required this.recipient,
    required this.userRole,
  });

  @override
  State<EditRecipientScreen> createState() => _EditRecipientScreenState();
}

class _EditRecipientScreenState extends State<EditRecipientScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _relationController;
  late final TextEditingController _phoneController;
  late DateTime _birthDate;
  late Gender _gender;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipient.name);
    _relationController = TextEditingController(text: widget.recipient.relation);
    _phoneController = TextEditingController(text: widget.recipient.phoneNumber);
    _birthDate = widget.recipient.birthDate;
    _gender = widget.recipient.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: '생년월일 선택',
      cancelText: '취소',
      confirmText: '선택',
    );

    if (selected != null) {
      setState(() => _birthDate = selected);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      widget.recipient.copyWith(
        name: _nameController.text.trim(),
        birthDate: _birthDate,
        gender: _gender,
        relation: _relationController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final relationLabel = widget.userRole == AppUserRole.socialWorker
        ? '관리 구분'
        : '보호자와의 관계';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '피보호자 정보 수정',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  _EditSection(
                    title: '기본 정보',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            label: '이름',
                            icon: Icons.person_outline,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '이름을 입력해 주세요.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _selectBirthDate,
                          child: InputDecorator(
                            decoration: _inputDecoration(
                              label: '생년월일',
                              icon: Icons.cake_outlined,
                            ),
                            child: Text(
                              _formatDate(_birthDate),
                              style: const TextStyle(
                                color: Color(0xFF263044),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<Gender>(
                          value: _gender,
                          decoration: _inputDecoration(
                            label: '성별',
                            icon: Icons.wc_outlined,
                          ),
                          items: Gender.values
                              .map(
                                (gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _gender = value);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _relationController,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            label: relationLabel,
                            icon: Icons.group_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '$relationLabel을 입력해 주세요.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _EditSection(
                    title: '연락 정보',
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      decoration: _inputDecoration(
                        label: '연락처',
                        icon: Icons.call_outlined,
                        hint: '010-0000-0000',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '연락처를 입력해 주세요.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _save(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('변경사항 저장'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

class _EditSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _EditSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF182033),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  required IconData icon,
  String? hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: const Color(0xFFF8F9FC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE1E5EE)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE1E5EE)),
    ),
  );
}

String _formatDate(DateTime date) {
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}
