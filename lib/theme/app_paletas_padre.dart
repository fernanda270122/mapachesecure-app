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
      primary: Color(0xFF2B6CB0), // Celeste sobrio
      accent: Color(0xFF90CDF4), // Celeste claro
      background: Color(0xFFF7FAFC), // Fondo limpio grisáceo
    ),
    'Café Beige': PaletaColorPadre(
      primary: Color(0xFF8C6239), // Café elegante
      accent: Color(0xFFD6C5B3), // Beige sutil
      background: Color(0xFFFDFBF7), // Fondo crema claro
    ),
    'Verde Olivo': PaletaColorPadre(
      primary: Color(0xFF2F855A), // Verde neutro
      accent: Color(0xFF9AE6B4), // Verde claro suave
      background: Color(0xFFF0FDF4), // Fondo matiz verde
    ),
  };
}
