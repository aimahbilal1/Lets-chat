import 'package:flutter/material.dart';

// Stateful so password-visibility toggle can own its own _showText state.
// Exposes all parameters needed for form validation, focus chaining, and
// keyboard type — none of which a StatelessWidget can provide.
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
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(widget.icon, color: Colors.grey.shade500, size: 20),
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                onPressed: () => setState(() => _showText = !_showText),
              )
            : null,
        filled: true,
        fillColor: widget.enabled ? Colors.white : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF4D7C63), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        errorStyle: const TextStyle(fontSize: 12),
      ),
    );
  }
}
