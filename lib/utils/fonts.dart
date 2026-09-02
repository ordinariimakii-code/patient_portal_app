import 'package:flutter/material.dart';

class AppFonts {
  static const String poppins = 'Poppins';
  
  static TextStyle heading1({Color? color}) {
    return TextStyle(
      fontFamily: poppins,
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: color,
      letterSpacing: 1.5,
    );
  }
  
  static TextStyle heading2({Color? color}) {
    return TextStyle(
      fontFamily: poppins,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: color,
      letterSpacing: 1,
    );
  }
  
  static TextStyle heading3({Color? color}) {
    return TextStyle(
      fontFamily: poppins,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }
  
  static TextStyle bodyLarge({Color? color}) {
    return TextStyle(
      fontFamily: poppins,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }
  
  static TextStyle bodyMedium({Color? color}) {
    return TextStyle(
      fontFamily: poppins,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }
  
  static TextStyle bodySmall({Color? color}) {
    return TextStyle(
      fontFamily: poppins,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }
  
  static TextStyle caption({Color? color}) {
    return TextStyle(
      fontFamily: poppins,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }
  
  static TextStyle button({Color? color}) {
    return TextStyle(
      fontFamily: poppins,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: 1.2,
    );
  }
}