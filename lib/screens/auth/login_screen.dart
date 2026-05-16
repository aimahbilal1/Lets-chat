import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/gradient_button.dart';
import '../chats/chats_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final re = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!re.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Must be at least 6 characters';
    return null;
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final error = await authService.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatsScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email address first')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final error = await authService.resetPassword(email);
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Reset link sent to $email'),
        backgroundColor: error != null ? AppColors.error : AppColors.accent,
      ),
    );
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.xxl),

                      // ─── App icon ──────────────────────────────────────────
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          boxShadow: AppShadow.card,
                        ),
                        child: const Icon(Icons.chat_bubble_outline,
                            size: 28, color: AppColors.accent),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      Text("Welcome back",
                          style: AppTextStyle.heading1.copyWith(fontSize: 24)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        "Sign in to continue",
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _fieldLabel("Email"),
                              const SizedBox(height: AppSpacing.xs),
                              CustomTextField(
                                hint: "you@example.com",
                                icon: Icons.alternate_email,
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) => FocusScope.of(context)
                                    .requestFocus(_passwordFocusNode),
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _fieldLabel("Password"),
                              const SizedBox(height: AppSpacing.xs),
                              CustomTextField(
                                hint: "••••••••",
                                icon: Icons.lock_outline,
                                obscure: true,
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) { if (!_isLoading) _login(); },
                                validator: _validatePassword,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _isLoading ? null : _forgotPassword,
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.accent,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
                                  ),
                                  child: Text("Forgot password?",
                                      style: AppTextStyle.caption.copyWith(
                                          color: AppColors.accent)),
                                ),
                              ),
                              GradientButton(
                                text: "Sign In",
                                onTap: _isLoading ? null : _login,
                                isLoading: _isLoading,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account?  ",
                              style: AppTextStyle.body2),
                          GestureDetector(
                            onTap: _isLoading ? null : () => Navigator.pop(context),
                            child: Text(
                              "Sign Up",
                              style: AppTextStyle.body2.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600),
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

  Widget _fieldLabel(String text) => Text(
        text,
        style: AppTextStyle.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      );
}
