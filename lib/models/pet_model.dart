class PetModel {
  final int puntos;
  const PetModel({this.puntos = 0});

  int get nivel {
    const List<int> puntosNivel = [
      0, 1000, 1250, 1500, 1750, 2000,
      2300, 2600, 2900, 3200, 3500,
      3850, 4200, 4550, 4900, 5250,
      5600, 5950, 6300, 6650, 7000,
    ];
    int n = 0;
    for (int i = 1; i < puntosNivel.length; i++) {
      if (puntos >= puntosNivel[i]) n = i;
      else break;
    }
    return n;
  }

  String get imagePath {
    if (nivel <= 0) return 'assets/mascota/raccu.png';
    if (nivel >= 6) return 'assets/mascota/magonivel6.png';
    return 'assets/mascota/magonivel$nivel.png';
  }
}
