class PetModel {
  final int puntos;
  const PetModel({this.puntos = 0});

  int get nivel {
    const List<int> puntosNivel = [
      0, 500, 1100, 1900, 2900, 4100, 5500,
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
