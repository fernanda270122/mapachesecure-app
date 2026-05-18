import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/theme/app_paletas.dart';

class TemaProvider extends ChangeNotifier {
  String _paleta = 'Lavanda';

  String get paleta => _paleta;
  PaletaColor get colores => AppPaletas.paletas[_paleta]!;

  Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    _paleta = prefs.getString('paleta_hijo') ?? 'Lavanda';
    notifyListeners();
  }

  Future<void> cambiar(String paleta) async {
    _paleta = paleta;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('paleta_hijo', paleta);
    notifyListeners();
  }
}
