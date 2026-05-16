import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/gradient_button.dart';
import '../auth/login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Name is required';
    if (v.trim().length < 2) return 'At least 2 characters';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final re = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!re.hasMatch(v.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'At least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Include one uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Include one number';
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final error = await authService.signUp(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created — please sign in')),
      );
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Stack(
          children: [
            Container(decoration: const BoxDecoration(gradient: AppColors.brandGradient)),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.xl),

                      // ─── Back + title ──────────────────────────────────────
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                boxShadow: AppShadow.card,
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded,
                                  size: 16, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      Text("Create account",
                          style: AppTextStyle.heading1.copyWith(fontSize: 30)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        "Join the conversation today",
                        style: AppTextStyle.body2,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ─── Form card ─────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.xxl),
                          boxShadow: AppShadow.card,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _label("Full Name"),
                            const SizedBox(height: AppSpacing.xs),
                            CustomTextField(
                              hint: "Your display name",
                              icon: Icons.person_outline,
                              controller: _nameController,
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) =>
                                  FocusScope.of(context).requestFocus(_emailFocusNode),
                              validator: _validateName,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _label("Email"),
                            const SizedBox(height: AppSpacing.xs),
                            CustomTextField(
                              hint: "you@example.com",
                              icon: Icons.alternate_email,
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) =>
                                  FocusScope.of(context).requestFocus(_passwordFocusNode),
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _label("Password"),
                            const SizedBox(height: AppSpacing.xs),
                            CustomTextField(
                              hint: "••••••••",
                              icon: Icons.lock_outline,
                              obscure: true,
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) =>
                                  FocusScope.of(context).requestFocus(_confirmFocusNode),
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _label("Confirm Password"),
                            const SizedBox(height: AppSpacing.xs),
                            CustomTextField(
                              hint: "••••••••",
                              icon: Icons.lock_outline,
                              obscure: true,
                              controller: _confirmPasswordController,
                              focusNode: _confirmFocusNode,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) =>
                                  FocusScope.of(context).requestFocus(_phoneFocusNode),
                              validator: _validateConfirmPassword,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _label("Phone (optional)"),
                            const SizedBox(height: AppSpacing.xs),
                            CustomTextField(
                              hint: "+1 555 000 0000",
                              icon: Icons.phone_outlined,
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) { if (!_isLoading) _signUp(); },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            GradientButton(
                              text: "Create Account",
                              onTap: _isLoading ? null : _signUp,
                              isLoading: _isLoading,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      Text(
                        "By joining you agree to our Terms & Privacy Policy.",
                        textAlign: TextAlign.center,
                        style: AppTextStyle.caption,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Already have an account?  ", style: AppTextStyle.body2),
                          GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () => Navigator.pushReplacement(context,
                                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                            child: Text(
                              "Sign In",
                              style: AppTextStyle.body2.copyWith(
                                  color: AppColors.accent, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppTextStyle.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      );
}
