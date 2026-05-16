import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

class AppInput extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool isDark;

  const AppInput(
      {super.key,
      this.label,
      this.hint,
      this.controller,
      this.obscureText = false,
      this.prefixIcon,
      this.suffixIcon,
      this.keyboardType,
      this.validator,
      this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppTokens.textPrimary;
    final hintColor = isDark ? Colors.white70 : Colors.black54;
    final fillColor = isDark ? AppTokens.darkSurface : AppTokens.surfaceInput;
    final borderColor = isDark ? AppTokens.darkBorder : AppTokens.border;
    final labelColor = isDark ? Colors.white70 : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.sp8),
            child: Text(
              label!,
              style: TextStyle(
                color: labelColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(fontSize: 14, color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: fillColor,
            hintStyle: TextStyle(color: hintColor, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusInput),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusInput),
              borderSide: BorderSide(color: borderColor, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusInput),
              borderSide: const BorderSide(color: AppTokens.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusInput),
              borderSide: const BorderSide(color: AppTokens.danger, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTokens.sp16, vertical: AppTokens.sp16),
          ),
        ),
      ],
    );
  }
}
