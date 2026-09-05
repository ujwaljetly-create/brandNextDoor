import 'package:flutter/material.dart';

class AppGradients {
  static const primary = LinearGradient(
    colors: [
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const glow = LinearGradient(
    colors: [
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
    ],
  );
}