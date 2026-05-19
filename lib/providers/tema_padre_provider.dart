import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/theme/app_paletas_padre.dart';

class TemaPadreProvider extends ChangeNotifier {
  String _paletaPadre = 'Celeste Neutro';

  String get paletaPadre => _paletaPadre;

  PaletaColorPadre get coloresPadre {
    return AppPaletasPadre.paletas[_paletaPadre] ??
        AppPaletasPadre.paletas['Celeste Neutro']!;
  }

  Future<void> cargarTemaPadre() async {
    final prefs = await SharedPreferences.getInstance();
    _paletaPadre =
        prefs.getString('paleta_padre_preferida') ?? 'Celeste Neutro';
    notifyListeners();
  }

  Future<void> cambiarTemaPadre(String nuevaPaleta) async {
    _paletaPadre = nuevaPaleta;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('paleta_padre_preferida', nuevaPaleta);
    notifyListeners();
  }
}
