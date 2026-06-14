import 'avatar_type.dart';

class PetModel {
  final int puntos;
  final String tipoAvatar;

  const PetModel({this.puntos = 0, this.tipoAvatar = 'mago'});

  int get nivel {
    const List<int> puntosNivel = [0, 500, 1100, 1900, 2900, 4100, 5500];
    int n = 0;
    for (int i = 1; i < puntosNivel.length; i++) {
      if (puntos >= puntosNivel[i]) {
        n = i;
      } else {
        break;
      }
    }
    return n;
  }

  String get imagePath {
    if (nivel <= 0) return 'assets/mascota/raccu.png';
    return AvatarTypes.byId(tipoAvatar).imagenNivel(nivel);
  }
}
