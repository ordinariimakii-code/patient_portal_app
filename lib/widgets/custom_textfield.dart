import 'package:flutter/material.dart';
import '../utils/colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final bool isPassword;
  final bool isGlass;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
    this.isPassword = false,
    this.isGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isGlass 
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGlass 
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: isGlass ? Colors.white : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            fontFamily: 'Poppins',
            color: isGlass 
                ? Colors.white.withValues(alpha: 0.7)
                : AppColors.textSecondary,
            fontSize: 14,
          ),
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            color: isGlass 
                ? Colors.white.withValues(alpha: 0.5)
                : AppColors.textLight,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: isGlass 
                ? Colors.white.withValues(alpha: 0.7)
                : AppColors.primary,
            size: 22,
          ),
          suffixIcon: suffixIcon,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: isGlass
              ? OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                )
              : const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
          filled: true,
          fillColor: isGlass 
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }
}