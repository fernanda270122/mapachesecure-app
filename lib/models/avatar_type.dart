class AvatarType {
  final String id;
  final String nombre;
  final String? videoPath;
  final List<String> imagenesNivel; // índice 0 = nivel 1 ... índice 5 = nivel 6

  const AvatarType({
    required this.id,
    required this.nombre,
    required this.imagenesNivel,
    this.videoPath,
  });

  String imagenNivel(int nivel) {
    final idx = nivel.clamp(1, 6) - 1;
    return imagenesNivel[idx];
  }

  String get preview => imagenesNivel[0];
}

class AvatarTypes {
  static const mago = AvatarType(
    id: 'mago',
    nombre: 'Mago',
    videoPath: 'assets/mascota/mago.mp4',
    imagenesNivel: [
      'assets/mascota/magonivel1.png',
      'assets/mascota/magonivel2.png',
      'assets/mascota/magonivel3.png',
      'assets/mascota/magonivel4.png',
      'assets/mascota/magonivel5.png',
      'assets/mascota/magonivel6.png',
    ],
  );

  static const dormilon = AvatarType(
    id: 'dormilon',
    nombre: 'Dormilón',
    videoPath: 'assets/mascota/dormilon_vd.mp4',
    imagenesNivel: [
      'assets/mascota/dormilon1.png',
      'assets/mascota/dormilon2.jpeg',
      'assets/mascota/dormilon3.jpeg',
      'assets/mascota/dormilon4.jpeg',
      'assets/mascota/dormilon5.jpeg',
      'assets/mascota/dormilon6.jpeg',
    ],
  );

  static const gamer = AvatarType(
    id: 'gamer',
    nombre: 'Gamer',
    videoPath: 'assets/mascota/gamer_vd.mp4',
    imagenesNivel: [
      'assets/mascota/gamer1.png',
      'assets/mascota/gamer2.jpeg',
      'assets/mascota/gamer3.jpeg',
      'assets/mascota/gamer4.jpeg',
      'assets/mascota/gamer5.jpeg',
      'assets/mascota/gamer6.jpeg',
    ],
  );

  static const ninja = AvatarType(
    id: 'ninja',
    nombre: 'Ninja',
    videoPath: 'assets/mascota/ninja_vd.mp4',
    imagenesNivel: [
      'assets/mascota/ninja1.jpeg',
      'assets/mascota/ninja2.jpeg',
      'assets/mascota/ninja3.jpeg',
      'assets/mascota/ninja4.jpeg',
      'assets/mascota/ninja5.jpeg',
      'assets/mascota/ninja6.jpeg',
    ],
  );

  static const samuray = AvatarType(
    id: 'samuray',
    nombre: 'Samurái',
    videoPath: 'assets/mascota/samuray_vd.mp4',
    imagenesNivel: [
      'assets/mascota/samuray1.png',
      'assets/mascota/samuray2.jpeg',
      'assets/mascota/samuray3.jpeg',
      'assets/mascota/samuray4.jpeg',
      'assets/mascota/samuray5.jpeg',
      'assets/mascota/samuray6.jpeg',
    ],
  );

  static const princes = AvatarType(
    id: 'princes',
    nombre: 'Princesa',
    videoPath: 'assets/mascota/princes_vd.mp4',
    imagenesNivel: [
      'assets/mascota/princes1.jpeg',
      'assets/mascota/princes2.jpeg',
      'assets/mascota/princes3.png',
      'assets/mascota/princes4.jpeg',
      'assets/mascota/princes5.jpeg',
      'assets/mascota/princes6.jpeg',
    ],
  );

  static const todos = [mago, dormilon, gamer, ninja, samuray, princes];

  static AvatarType byId(String id) =>
      todos.firstWhere((a) => a.id == id, orElse: () => mago);
}
