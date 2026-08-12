import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import '../services/api_client.dart';
import '../services/call_schedule_service.dart';
import '../services/recipient_service.dart';

const _relationOptions = <String, String>{
  'CHILD': '자녀',
  'PARENT': '부모',
  'SPOUSE': '배우자',
  'SIBLING': '형제/자매',
  'CAREGIVER': '간병인',
  'ADMIN': '담당 피보호자',
  'OTHER': '기타',
};

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
  late final TextEditingController _lastNameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _intervalDaysController;
  late DateTime _birthDate;
  late Gender _gender;
  late String _relationKey;
  TimeOfDay? _callTime;
  int? _callScheduleId;
  bool _callScheduleIsActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _lastNameController =
        TextEditingController(text: widget.recipient.lastName);
    _firstNameController =
        TextEditingController(text: widget.recipient.firstName);
    _phoneController = TextEditingController(text: widget.recipient.phoneNumber);
    _addressController = TextEditingController(text: widget.recipient.address ?? '');
    _intervalDaysController = TextEditingController(text: '1');
    _birthDate = widget.recipient.birthDate;
    _gender = widget.recipient.gender;
    _relationKey = _relationOptions.entries
        .firstWhere(
          (e) => e.value == widget.recipient.relation,
          orElse: () => const MapEntry('OTHER', '기타'),
        )
        .key;
    _loadCallSchedule();
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _intervalDaysController.dispose();
    super.dispose();
  }

  Future<void> _loadCallSchedule() async {
    try {
      final schedules =
          await CallScheduleService().findByRecipient(widget.recipient.id);
      if (!mounted || schedules.isEmpty) return;
      final schedule = schedules.first;
      setState(() {
        _callScheduleId = schedule.id;
        _callTime = schedule.scheduledTime;
        _callScheduleIsActive = schedule.isActive;
        _intervalDaysController.text = (schedule.intervalDays ?? 1).toString();
      });
    } catch (_) {
      // 예약된 시간대가 없거나 조회에 실패하면 새로 등록할 수 있도록 조용히 넘어갑니다.
    }
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

  Future<void> _pickCallTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _callTime ?? const TimeOfDay(hour: 10, minute: 0),
      helpText: '전화 예약 시간대 선택',
      cancelText: '취소',
      confirmText: '선택',
    );
    if (picked != null) setState(() => _callTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final updated = await RecipientService().updateRecipient(
        id: widget.recipient.id,
        lastName: _lastNameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        birthDate: _birthDate,
        gender: _gender,
        relationToGuardian: _relationKey,
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      );

      if (_callTime != null) {
        final intervalDays = int.tryParse(_intervalDaysController.text.trim());
        if (_callScheduleId != null) {
          await CallScheduleService().update(
            id: _callScheduleId!,
            recipientId: widget.recipient.id,
            scheduledTime: _callTime!,
            intervalDays: intervalDays,
            isActive: _callScheduleIsActive,
          );
        } else {
          final created = await CallScheduleService().create(
            recipientId: widget.recipient.id,
            scheduledTime: _callTime!,
            intervalDays: intervalDays,
            isActive: _callScheduleIsActive,
          );
          _callScheduleId = created.id;
        }
      } else if (_callScheduleId != null) {
        await CallScheduleService().delete(_callScheduleId!);
        _callScheduleId = null;
      }

      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } on NetworkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장에 실패했습니다. 네트워크를 확인해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _lastNameController,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(
                                  label: '성',
                                  icon: Icons.person_outline,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '필수';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _firstNameController,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(
                                  label: '이름',
                                  icon: Icons.person_outline,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '필수';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
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
                        DropdownButtonFormField<String>(
                          value: _relationKey,
                          decoration: _inputDecoration(
                            label: relationLabel,
                            icon: Icons.group_outlined,
                          ),
                          items: _relationOptions.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _relationKey = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _EditSection(
                    title: '연락 정보',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
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
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _addressController,
                          textInputAction: TextInputAction.done,
                          decoration: _inputDecoration(
                            label: '주소',
                            icon: Icons.home_outlined,
                            hint: '예: 서울특별시 강남구 ...',
                          ),
                          onFieldSubmitted: (_) => _save(),
                        ),
                        const SizedBox(height: 14),
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _pickCallTime,
                          child: InputDecorator(
                            decoration: _inputDecoration(
                              label: '전화 예약 시간대',
                              icon: Icons.schedule_outlined,
                              hint: '예: 오전 10:00',
                            ).copyWith(
                              suffixIcon: _callTime == null
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 18),
                                      onPressed: () => setState(() => _callTime = null),
                                    ),
                            ),
                            child: Text(
                              _callTime == null
                                  ? '예: 오전 10:00'
                                  : formatTimeOfDayKo(_callTime!),
                              style: TextStyle(
                                color: _callTime == null
                                    ? const Color(0xFF9AA2B4)
                                    : const Color(0xFF263044),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (_callTime != null) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _intervalDaysController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            decoration: _inputDecoration(
                              label: '반복 간격 (일)',
                              icon: Icons.repeat_rounded,
                              hint: '예: 1(매일), 7(매주)',
                            ),
                            validator: (value) {
                              if (_callTime == null) return null;
                              final n = int.tryParse((value ?? '').trim());
                              if (n == null || n <= 0) {
                                return '1 이상의 숫자를 입력해 주세요.';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _save(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
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