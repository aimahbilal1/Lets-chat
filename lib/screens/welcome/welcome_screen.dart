import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Decorative gradient — background only, never on interactive elements
          Container(decoration: const BoxDecoration(gradient: AppColors.brandGradient)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xl),

                  // ─── Eyebrow label ────────────────────────────────────────
                  Text(
                    "MESSAGING REIMAGINED",
                    style: AppTextStyle.caption.copyWith(
                      letterSpacing: 1.5,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ─── Hero heading ─────────────────────────────────────────
                  Text(
                    "Welcome to\nLet's Chat",
                    style: AppTextStyle.heading1.copyWith(fontSize: 34),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Text(
                    "Calm, focused conversations.\nYour words, your space.",
                    style: AppTextStyle.body1.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ─── Social proof ─────────────────────────────────────────
                  Row(
                    children: [
                      _AvatarStack(),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("10k+ joined today",
                              style: AppTextStyle.label.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              )),
                          Text("Join the community",
                              style: AppTextStyle.caption.copyWith(
                                color: AppColors.textSecondary,
                              )),
                        ],
                      )
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ─── Feature pills ────────────────────────────────────────
                  _FeaturePill(icon: Icons.lock_outline, label: "End-to-end encrypted"),
                  const SizedBox(height: AppSpacing.sm),
                  _FeaturePill(icon: Icons.flash_on_outlined, label: "Instant delivery"),
                  const SizedBox(height: AppSpacing.sm),
                  _FeaturePill(icon: Icons.palette_outlined, label: "Beautiful, minimal design"),

                  const Spacer(),

                  // ─── CTA ──────────────────────────────────────────────────
                  GradientButton(
                    text: "Get Started",
                    onTap: () => Navigator.push(
                      context,
                      _slide(const SignupScreen()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: "Already have an account?  ",
                        style: AppTextStyle.body2,
                        children: [
                          TextSpan(
                            text: "Log In",
                            style: AppTextStyle.body2.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => Navigator.push(context, _slide(const LoginScreen())),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PageRouteBuilder _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      );
}

class _AvatarStack extends StatelessWidget {
  final List<Color> _colors = const [
    Color(0xFF7B9E87), Color(0xFFC08080), Color(0xFF8080C0),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 36,
      child: Stack(
        children: List.generate(_colors.length, (i) => Positioned(
          left: i * 20.0,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _colors[i],
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 2),
            ),
          ),
        )),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTextStyle.body2.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
