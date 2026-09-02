import 'package:flutter/material.dart';
import 'liquid_glass_container.dart';

class LiquidGlassTextField extends StatelessWidget {
  final String hintText;
  final IconData? icon;
  final bool obscureText;
  final TextEditingController controller;
  final Widget? suffixIcon;
  final TextInputType keyboardType;

  const LiquidGlassTextField({
    super.key,
    required this.hintText,
    this.icon,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      borderRadius: 14.0,
      tintColor: const Color(0xFF16091E),
      tintOpacity: 0.55,
      blurSigma: 12.0,
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16.0,
          fontFamily: 'Inter',
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
          icon: icon != null ? Icon(icon, color: Colors.white60, size: 22) : null,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF726A7A),
            fontSize: 16.0,
            fontFamily: 'Inter',
          ),
          suffixIcon: suffixIcon,
          suffixIconConstraints: const BoxConstraints(maxHeight: 42, maxWidth: 42),
        ),
      ),
    );
  }
}
