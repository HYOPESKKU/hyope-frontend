import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/auth_form_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _authService = AuthService();

  DateTime? _birthDate;
  String _gender = 'MALE'; // 'MALE' | 'FEMALE'
  String _role = 'GUARDIAN'; // 'GUARDIAN' | 'ORG_ADMIN'
  bool _isLoading = false;

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('생년월일을 선택해주세요')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.register(
        loginId: _loginIdController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        birthDate: _birthDate!,
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        gender: _gender,
        role: _role,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입이 완료되었습니다. 로그인해주세요.')),
      );
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF182033),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'HYOPE 회원가입',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF182033),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '서비스 이용을 위해 아래 정보를 입력해주세요.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF7A8294)),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      '가입 유형',
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
                            label: '보호자',
                            selected: _role == 'GUARDIAN',
                            onTap: () => setState(() => _role = 'GUARDIAN'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AuthChoiceChip(
                            label: '복지사(기관 관리자)',
                            selected: _role == 'ORG_ADMIN',
                            onTap: () => setState(() => _role = 'ORG_ADMIN'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

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
                              decoration: authInputDecoration(hint: '민준'),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? '필수' : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    LabeledField(
                      label: '아이디',
                      child: TextFormField(
                        controller: _loginIdController,
                        decoration: authInputDecoration(hint: '영문/숫자 조합'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? '아이디를 입력해주세요'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    LabeledField(
                      label: '비밀번호',
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: authInputDecoration(hint: '비밀번호를 입력하세요'),
                        validator: (v) => (v == null || v.length < 8)
                            ? '비밀번호는 8자 이상 입력해주세요'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    LabeledField(
                      label: '비밀번호 확인',
                      child: TextFormField(
                        controller: _passwordConfirmController,
                        obscureText: true,
                        decoration: authInputDecoration(hint: '비밀번호를 다시 입력하세요'),
                        validator: (v) => v != _passwordController.text
                            ? '비밀번호가 일치하지 않습니다'
                            : null,
                      ),
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
                            selected: _gender == 'MALE',
                            onTap: () => setState(() => _gender = 'MALE'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AuthChoiceChip(
                            label: '여성',
                            selected: _gender == 'FEMALE',
                            onTap: () => setState(() => _gender = 'FEMALE'),
                          ),
                        ),
                      ],
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
                      label: '이메일',
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: authInputDecoration(hint: 'example@email.com'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return '필수';
                          if (!v.contains('@')) return '이메일 형식이 올바르지 않습니다';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F80FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '가입하기',
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