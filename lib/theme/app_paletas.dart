import 'package:flutter/material.dart';

class PaletaColor {
  final Color primary;
  final Color accent;
  final Color background;
  final Color onBackground;

  const PaletaColor({
    required this.primary,
    required this.accent,
    required this.background,
    required this.onBackground,
  });
}

class AppPaletas {
  static const Map<String, PaletaColor> paletas = {
    'Lavanda': PaletaColor(
      primary: Color(0xFF7E57C2),
      accent: Color(0xFF9575CD),
      background: Color(0xFFEDE7F6),
      onBackground: Color(0xFF311B92),
    ),
    'Salvia': PaletaColor(
      primary: Color(0xFF5D9B6B),
      accent: Color(0xFF81B581),
      background: Color(0xFFE8F5E9),
      onBackground: Color(0xFF1B5E20),
    ),
    'Cielo': PaletaColor(
      primary: Color(0xFF42A5F5),
      accent: Color(0xFF64B5F6),
      background: Color(0xFFE3F2FD),
      onBackground: Color(0xFF0D47A1),
    ),
    'Arena': PaletaColor(
      primary: Color(0xFF8D6E4A),
      accent: Color(0xFFAA8860),
      background: Color(0xFFF5E6D3),
      onBackground: Color(0xFF4E342E),
    ),
  };
}
