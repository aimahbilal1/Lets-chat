import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.text,
    this.onTap,
    this.isLoading = false,
  });

  bool get _isActive => onTap != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isActive ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        opacity: _isActive ? 1.0 : 0.6,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: AppColors.buttonGradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}
