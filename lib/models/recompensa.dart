class Recompensa {
  final String id;
  final String titulo;
  final String descripcion;
  final int costoPuntos;
  final String icono; // nombre del icono o emoji
  final bool disponible;
  final String? padreId; // quién creó la recompensa
  final DateTime? fechaCreacion;

  Recompensa({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.costoPuntos,
    this.icono = 'stars',
    this.disponible = true,
    this.padreId,
    this.fechaCreacion,
  });

  /// Crea una Recompensa desde el JSON que devuelve el backend
  factory Recompensa.fromJson(Map<String, dynamic> json) {
    return Recompensa(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      costoPuntos: json['costo_puntos'] != null
          ? (json['costo_puntos'] as num).toInt()
          : 0,
      icono: json['icono'] ?? 'stars',
      disponible: json['disponible'] ?? true,
      padreId: json['padre_id']?.toString(),
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.tryParse(json['fecha_creacion'])
          : null,
    );
  }

  /// Convierte la Recompensa a JSON para enviarlo al backend
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'costo_puntos': costoPuntos,
      'icono': icono,
      'disponible': disponible,
      if (padreId != null) 'padre_id': padreId,
      if (fechaCreacion != null)
        'fecha_creacion': fechaCreacion!.toIso8601String(),
    };
  }

  Recompensa copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    int? costoPuntos,
    String? icono,
    bool? disponible,
    String? padreId,
    DateTime? fechaCreacion,
  }) {
    return Recompensa(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      costoPuntos: costoPuntos ?? this.costoPuntos,
      icono: icono ?? this.icono,
      disponible: disponible ?? this.disponible,
      padreId: padreId ?? this.padreId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  /// Verifica si el hijo tiene suficientes puntos para canjear
  bool puedesCanjear(int puntosHijo) => puntosHijo >= costoPuntos;

  @override
  String toString() =>
      'Recompensa(id: $id, titulo: $titulo, costo: $costoPuntos pts)';
}
