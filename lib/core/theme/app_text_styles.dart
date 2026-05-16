import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_tokens.dart';

class AppText {
  static TextStyle display({Color? color, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: weight,
          color: color ?? AppTokens.textPrimary);

  static TextStyle heading({Color? color, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: weight,
          color: color ?? AppTokens.textPrimary);

  static TextStyle title({Color? color, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: weight,
          color: color ?? AppTokens.textPrimary);

  static TextStyle body({Color? color, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: weight,
          color: color ?? AppTokens.textPrimary, height: 1.6);

  static TextStyle small({Color? color, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: weight,
          color: color ?? AppTokens.textSecondary);

  static TextStyle muted({Color? color}) =>
      GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w400,
          color: color ?? AppTokens.textMuted);

  static TextStyle button({Color? color}) =>
      GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700,
          color: color ?? Colors.white, letterSpacing: 0.2);
}
