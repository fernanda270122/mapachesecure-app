class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String rol; // 'padre' o 'hijo'
  final int? edad; // solo para hijos
  final int tiempoLimiteMinutos; // límite diario de pantalla
  //final int totalPuntos;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.edad,
    this.tiempoLimiteMinutos = 120,
    //this.totalPuntos = 0,
  });

  /// Crea un Usuario desde el JSON que devuelve el backend
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      rol: json['rol'] ?? 'hijo',
      edad: json['edad'] != null ? (json['edad'] as num).toInt() : null,
      tiempoLimiteMinutos: json['tiempo_limite_minutos'] != null
          ? (json['tiempo_limite_minutos'] as num).toInt()
          : 120,
      // totalPuntos: json['total_puntos'] != null
      //     ? (json['total_puntos'] as num).toInt()
      //     : 0,
      //totalPuntos: 0,
    );
  }

  /// Convierte el Usuario a JSON para enviarlo al backend
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      if (edad != null) 'edad': edad,
      'tiempo_limite_minutos': tiempoLimiteMinutos,
      //'total_puntos': totalPuntos,
    };
  }

  /// Copia el usuario con campos modificados
  Usuario copyWith({
    String? id,
    String? nombre,
    String? email,
    String? rol,
    int? edad,
    int? tiempoLimiteMinutos,
    //int? totalPuntos,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      edad: edad ?? this.edad,
      tiempoLimiteMinutos: tiempoLimiteMinutos ?? this.tiempoLimiteMinutos,
      //totalPuntos: totalPuntos ?? this.totalPuntos,
    );
  }

  bool get esPadre => rol == 'padre';
  bool get esHijo => rol == 'hijo';

  @override
  String toString() => 'Usuario(id: $id, nombre: $nombre, rol: $rol)';
}