import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _department = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _department.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final res = await AuthService.register(
      fullName: _fullName.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      confirmPassword: _confirmPassword.text,
      department: _department.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            userId: res['user_id'],
            purpose: 'register',
            email: _email.text.trim(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Let’s get started', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -.7)),
                    const SizedBox(height: 6),
                    const Text('Create your TaskFlow account to manage your work.', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 28),
                    _field('Full Name', _fullName, 'Juan Dela Cruz', Icons.person_outline_rounded, validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                    const SizedBox(height: 15),
                    _field('Email', _email, 'you@company.com', Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress, validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null),
                    const SizedBox(height: 15),
                    _field('Department', _department, 'e.g. IT, HR, Operations', Icons.business_center_outlined, validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                    const SizedBox(height: 15),
                    _passwordField('Password', _password, _obscure, () => setState(() => _obscure = !_obscure), 'At least 8 characters', (v) => (v == null || v.length < 8) ? 'Minimum 8 characters' : null),
                    const SizedBox(height: 15),
                    _passwordField('Confirm Password', _confirmPassword, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm), 'Re-enter your password', (v) => v != _password.text ? 'Passwords do not match' : null),
                    const SizedBox(height: 25),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.person_add_alt_1_rounded, size: 19),
                      label: Text(_loading ? 'Creating account...' : 'Create Account'),
                    ),
                    const SizedBox(height: 17),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.maybePop(context),
                        child: const Text('Already have an account? Sign in', style: TextStyle(fontWeight: FontWeight.w700)),
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

  Widget _field(String label, TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
          validator: validator,
        ),
      ],
    );
  }

  Widget _passwordField(String label, TextEditingController controller, bool obscure, VoidCallback toggle, String hint, String? Function(String?) validator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: obscure ? 'Show password' : 'Hide password',
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: toggle,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
  );
}
