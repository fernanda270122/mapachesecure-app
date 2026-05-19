import 'package:flutter/material.dart';

class PaletaColorPadre {
  final Color primary;
  final Color accent;
  final Color background;

  const PaletaColorPadre({
    required this.primary,
    required this.accent,
    required this.background,
  });
}

class AppPaletasPadre {
  static const Map<String, PaletaColorPadre> paletas = {
    'Celeste Neutro': PaletaColorPadre(
      primary: Color(0xFF2B6CB0),
      accent: Color(0xFF90CDF4),
      background: Color(0xFFF7FAFC),
    ),
    'Café Beige': PaletaColorPadre(
      primary: Color(0xFF8C6239),
      accent: Color(0xFFD6C5B3),
      background: Color(0xFFFDFBF7),
    ),
    'Verde Olivo': PaletaColorPadre(
      primary: Color(0xFF2F855A),
      accent: Color(0xFF9AE6B4),
      background: Color(0xFFF0FDF4),
    ),
    'Damasco': PaletaColorPadre(
      primary: Color(0xFFE07A5F),
      accent: Color(0xFFF4A261),
      background: Color(0xFFFFFDFB),
    ),
    'Lila Pastel': PaletaColorPadre(
      primary: Color(0xFF8E7DBE),
      accent: Color(0xFFD7BDE2),
      background: Color(0xFFFDFBFE),
    ),
    'Turquesa': PaletaColorPadre(
      primary: Color(0xFF3B9A9C),
      accent: Color(0xFF4DB6AC),
      background: Color(0xFFF4FAFA),
    ),
    'Negro Absoluto': PaletaColorPadre(
      primary: Color(0xFF1A1A1A),
      accent: Color(0xFFCBD5E1),
      background: Color(0xFF121212),
    ),
    'Blanco grisáceo': PaletaColorPadre(
      primary: Color.fromARGB(255, 153, 156, 163),
      accent: Color(0xFFCBD5E1),
      background: Color(0xFFFFFFFF),
    ),
    'Azul Pastel': PaletaColorPadre(
      primary: Color(0xFF6BAED6),
      accent: Color(0xFF9ECAE1),
      background: Color(0xFFF7FAFC),
    ),
  };
}
