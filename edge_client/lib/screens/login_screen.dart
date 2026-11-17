import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Luxury Clinical Authentication Portal for SkinGuard UAE & Malaffi HIE.
class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final bool isArabic;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    this.isArabic = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isRegisterMode = false;
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(text: 'demo@skinguard.ae');
  final _passwordController = TextEditingController(text: 'AbuDhabi2026!');
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'citizen';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    if (_isRegisterMode) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Passwords do not match.');
        return;
      }

      final result = await AuthService.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
      );

      setState(() => _isLoading = false);
      if (result.success) {
        widget.onLoginSuccess();
      } else {
        _showErrorSnackBar(result.message);
      }
    } else {
      final result = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      if (result.success) {
        widget.onLoginSuccess();
      } else {
        _showErrorSnackBar(result.message);
      }
    }
  }

  void _fastDemoLogin() async {
    setState(() {
      _isRegisterMode = false;
      _emailController.text = 'demo@skinguard.ae';
      _passwordController.text = 'AbuDhabi2026!';
      _isLoading = true;
    });

    final res = await AuthService.login(
      email: 'demo@skinguard.ae',
      password: 'AbuDhabi2026!',
      rememberMe: true,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (res.success) {
      widget.onLoginSuccess();
    } else {
      _showErrorSnackBar(res.message);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordSheet() {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    final codeCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    bool isCodeSent = false;
    bool isSubmitting = false;
    String? statusErrorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lock_reset_rounded, color: Color(0xFF0284C7), size: 22),
                      SizedBox(width: 8),
                      Text('Secure Password Recovery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(modalCtx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your verified email to receive a 6-digit one-time cryptographic recovery code (valid for 10 minutes).',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.35),
              ),
              const SizedBox(height: 16),

              if (statusErrorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          statusErrorMessage!,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF991B1B)),
                        ),
                      ),
                    ],
                  ),
                ),

              if (!isCodeSent) ...[
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Registered Health Email',
                    prefixIcon: const Icon(Icons.email_outlined, size: 18, color: Color(0xFF0284C7)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (emailCtrl.text.trim().isEmpty) return;
                            setModalState(() {
                              isSubmitting = true;
                              statusErrorMessage = null;
                            });
                            final res = await AuthService.forgotPassword(emailCtrl.text.trim());
                            if (!modalCtx.mounted) return;
                            setModalState(() {
                              isSubmitting = false;
                              if (res.success) {
                                isCodeSent = true;
                                statusErrorMessage = null;
                              } else {
                                statusErrorMessage = res.message;
                              }
                            });
                          },
                    child: isSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Send 6-Digit Security Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.mark_email_read_rounded, color: Color(0xFF059669), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SECURITY CODE DISPATCHED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF166534))),
                            const SizedBox(height: 2),
                            Text(
                              'A 6-digit verification code was dispatched to ${emailCtrl.text.trim()}. Please check your email inbox and enter the code below.',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF15803D)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                TextField(
                  controller: codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: '6-Digit Verification Code',
                    hintText: 'Enter code from email',
                    prefixIcon: const Icon(Icons.pin_outlined, size: 18, color: Color(0xFF0284C7)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newPwdCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Set New Password (min. 6 chars)',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF0284C7)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final code = codeCtrl.text.trim();
                            final newPwd = newPwdCtrl.text;
                            if (code.length != 6) {
                              setModalState(() {
                                statusErrorMessage = 'Please enter the complete 6-digit verification code from your email.';
                              });
                              return;
                            }
                            if (newPwd.length < 6) {
                              setModalState(() {
                                statusErrorMessage = 'New password must be at least 6 characters long.';
                              });
                              return;
                            }
                            setModalState(() {
                              isSubmitting = true;
                              statusErrorMessage = null;
                            });
                            final res = await AuthService.resetPassword(
                              email: emailCtrl.text.trim(),
                              code: code,
                              newPassword: newPwd,
                            );
                            if (!modalCtx.mounted) return;
                            setModalState(() => isSubmitting = false);
                            if (res.success) {
                              Navigator.pop(modalCtx);
                              _passwordController.text = newPwd;
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF059669),
                                  content: Text(res.message),
                                ),
                              );
                            } else {
                              if (!mounted) return;
                              _showErrorSnackBar(res.message);
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Confirm & Update Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgSurface = Color(0xFFF8FAFC);
    const brandSky = Color(0xFF0284C7);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);
    const borderSubtle = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgSurface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Badge & Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ABU DHABI DOH • FUTURE HEALTH',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: brandSky, letterSpacing: 0.8),
                          ),
                          Text(
                            widget.isArabic ? 'سكين جارد أبوظبي' : 'SkinGuard UAE',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Mode Toggle Tab
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isRegisterMode = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isRegisterMode ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !_isRegisterMode ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)] : null,
                              ),
                              child: Center(
                                child: Text(
                                  widget.isArabic ? 'تسجيل الدخول' : 'Sign In',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: !_isRegisterMode ? textPrimary : textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isRegisterMode = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isRegisterMode ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _isRegisterMode ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)] : null,
                              ),
                              child: Center(
                                child: Text(
                                  widget.isArabic ? 'إنشاء حساب جديد' : 'Create Account',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: _isRegisterMode ? textPrimary : textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Full Name (Only on Registration)
                  if (_isRegisterMode) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'e.g. Dr. Mariam Al-Zaabi',
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: brandSky),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderSubtle)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderSubtle)),
                      ),
                      validator: (v) => (v == null || v.trim().length < 2) ? 'Please enter your full name.' : null,
                    ),
                    const SizedBox(height: 14),

                    // Role Picker
                    Row(
                      children: [
                        const Text('Role: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary)),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Citizen / Patient', style: TextStyle(fontSize: 10.5)),
                          selected: _selectedRole == 'citizen',
                          onSelected: (s) => setState(() => _selectedRole = 'citizen'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Clinician (Malaffi)', style: TextStyle(fontSize: 10.5)),
                          selected: _selectedRole == 'clinician_navigator',
                          onSelected: (s) => setState(() => _selectedRole = 'clinician_navigator'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Registered Health Email',
                      prefixIcon: const Icon(Icons.email_outlined, size: 18, color: brandSky),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderSubtle)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderSubtle)),
                    ),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Please enter a valid email address.' : null,
                  ),
                  const SizedBox(height: 14),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: brandSky),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: textSecondary),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderSubtle)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderSubtle)),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters.' : null,
                  ),

                  // Confirm Password (Only on Registration)
                  if (_isRegisterMode) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_clock_outlined, size: 18, color: brandSky),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: textSecondary),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderSubtle)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderSubtle)),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Please confirm your password.' : null,
                    ),
                  ],

                  // Remember Me & Forgot Password Row (Only in Login Mode)
                  if (!_isRegisterMode) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: brandSky,
                                onChanged: (v) => setState(() => _rememberMe = v ?? true),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('Remember Me', style: TextStyle(fontSize: 11, color: textSecondary)),
                          ],
                        ),
                        TextButton(
                          onPressed: _showForgotPasswordSheet,
                          child: const Text('Forgot Password?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: brandSky)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandSky,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _isRegisterMode ? 'Create Account & Continue' : 'Sign In to Health Portal',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 1-Tap Judge / Fast Demo Login Chip
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bolt_rounded, color: Color(0xFF059669), size: 20),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('HACKATHON JUDGE DEMO ACCESS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF166534))),
                                Text('Nurse Fatima Al-Mansouri (SEHA)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _isLoading ? null : _fastDemoLogin,
                          child: const Text('1-Tap Sign In', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
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
