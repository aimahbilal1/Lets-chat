import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';

/// Design-system text field — filled style, accent focus ring, clean error state.
class CustomTextField extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final bool autofocus;
  final bool enabled;

  const CustomTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.onSubmitted,
    this.validator,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _showText = false;

  @override
  Widget build(BuildContext context) {
    final obscureText = widget.obscure && !_showText;

    return TextFormField(
      controller: widget.controller,
      obscureText: obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      focusNode: widget.focusNode,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      autocorrect: !widget.obscure,
      enableSuggestions: !widget.obscure,
      style: AppTextStyle.body1.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: Icon(widget.icon, color: AppColors.textTertiary, size: 20),
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
                onPressed: () => setState(() => _showText = !_showText),
              )
            : null,
      ),
    );
  }
}
