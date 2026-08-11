import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import '../services/api_client.dart';
import '../services/call_schedule_service.dart';
import '../services/recipient_service.dart';
import '../widgets/auth_form_widgets.dart';

const _onboardingRelationOptions = <String, String>{
  'PARENT': '부모',
  'CHILD': '자녀',
  'SPOUSE': '배우자',
  'SIBLING': '형제/자매',
  'CAREGIVER': '간병인',
  'OTHER': '기타',
};

class RecipientOnboardingScreen extends StatefulWidget {
  final int guardianId;

  const RecipientOnboardingScreen({super.key, required this.guardianId});

  @override
  State<RecipientOnboardingScreen> createState() =>
      _RecipientOnboardingScreenState();
}

class _RecipientOnboardingScreenState extends State<RecipientOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _intervalDaysController = TextEditingController(text: '1');

  DateTime? _birthDate;
  Gender _gender = Gender.male;
  String _relationKey = 'PARENT';
  TimeOfDay? _callTime;
  bool _isSaving = false;

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _intervalDaysController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 70),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
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
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('생년월일을 선택해주세요')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final created = await RecipientService().createRecipient(
        guardianId: widget.guardianId,
        lastName: _lastNameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        birthDate: _birthDate!,
        gender: _gender,
        relationToGuardian: _relationKey,
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      );
      if (_callTime != null) {
        try {
          await CallScheduleService().create(
            recipientId: created.id,
            scheduledTime: _callTime!,
            intervalDays: int.tryParse(_intervalDaysController.text.trim()),
          );
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('전화 예약 시간대 저장에 실패했습니다. 정보 수정 화면에서 다시 설정해주세요.'),
              ),
            );
          }
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop(created);
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
        const SnackBar(content: Text('등록에 실패했습니다. 네트워크를 확인해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
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
                        Icons.family_restroom_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      '피보호자 등록',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF182033),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '돌봄이 필요한 대상자 정보를 등록해주세요. 나중에 정보 수정 화면에서 언제든 바꿀 수 있어요.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: Color(0xFF7A8294),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: LabeledField(
                            label: '성',
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: authInputDecoration(hint: '김'),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? '필수' : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LabeledField(
                            label: '이름',
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: authInputDecoration(hint: '영희'),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? '필수' : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: '생년월일',
                      child: InkWell(
                        onTap: _pickBirthDate,
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration: authInputDecoration(hint: 'YYYY-MM-DD'),
                          child: Text(
                            _birthDate == null
                                ? 'YYYY-MM-DD'
                                : '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: _birthDate == null
                                  ? const Color(0xFF9AA2B4)
                                  : const Color(0xFF182033),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '성별',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF182033),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: AuthChoiceChip(
                            label: '남성',
                            selected: _gender == Gender.male,
                            onTap: () => setState(() => _gender = Gender.male),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AuthChoiceChip(
                            label: '여성',
                            selected: _gender == Gender.female,
                            onTap: () => setState(() => _gender = Gender.female),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: '나와의 관계',
                      child: DropdownButtonFormField<String>(
                        initialValue: _relationKey,
                        decoration: authInputDecoration(hint: '관계 선택'),
                        items: _onboardingRelationOptions.entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _relationKey = value);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: '휴대폰 번호',
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: authInputDecoration(hint: '010-1234-5678'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? '필수' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: '주소',
                      child: TextFormField(
                        controller: _addressController,
                        decoration: authInputDecoration(hint: '예: 서울특별시 강남구 ...'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: '전화 예약 시간대',
                      child: InkWell(
                        onTap: _pickCallTime,
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration: authInputDecoration(hint: '예: 오전 10:00').copyWith(
                            suffixIcon: _callTime == null
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    onPressed: () => setState(() => _callTime = null),
                                  ),
                          ),
                          child: Text(
                            _callTime == null ? '예: 오전 10:00' : formatTimeOfDayKo(_callTime!),
                            style: TextStyle(
                              color: _callTime == null
                                  ? const Color(0xFF9AA2B4)
                                  : const Color(0xFF182033),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_callTime != null) ...[
                      const SizedBox(height: 16),
                      LabeledField(
                        label: '반복 간격 (일)',
                        child: TextFormField(
                          controller: _intervalDaysController,
                          keyboardType: TextInputType.number,
                          decoration: authInputDecoration(hint: '예: 1(매일), 7(매주)'),
                          validator: (v) {
                            if (_callTime == null) return null;
                            final n = int.tryParse((v ?? '').trim());
                            if (n == null || n <= 0) {
                              return '1 이상의 숫자를 입력해 주세요.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F80FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '등록하고 시작하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}