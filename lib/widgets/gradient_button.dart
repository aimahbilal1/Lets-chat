import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';

/// Primary CTA button — solid accent, pill shape, press-scale micro-interaction.
/// No gradient on interactive elements (design spec).
class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.text,
    this.onTap,
    this.isLoading = false,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    reverseDuration: const Duration(milliseconds: 150),
    lowerBound: 0.97,
    upperBound: 1.0,
    value: 1.0,
  );

  bool get _isActive => widget.onTap != null && !widget.isLoading;

  void _onTapDown(_) { if (_isActive) _controller.reverse(); }
  void _onTapUp(_)   { _controller.forward(); }
  void _onCancel()   { _controller.forward(); }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onCancel,
      onTap: _isActive ? widget.onTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _controller.value,
          child: child,
        ),
        child: AnimatedOpacity(
          opacity: _isActive ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppRadius.full),
              boxShadow: _isActive ? AppShadow.elevated : null,
            ),
            alignment: Alignment.center,
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.text,
                    style: AppTextStyle.label.copyWith(color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}
