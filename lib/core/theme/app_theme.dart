import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,

    scaffoldBackgroundColor: const Color(0xFF070B1A),

    textTheme: GoogleFonts.poppinsTextTheme(),

    useMaterial3: true,
  );
}