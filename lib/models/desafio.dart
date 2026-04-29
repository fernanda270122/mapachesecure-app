class Desafio {
  final String id;
  final String titulo;
  final String descripcion;
  final String categoria; // 'cognitiva', 'fisica', 'hogar'
  final int puntos;
  final int tiempoEstimadoMinutos;
  final String estado; // 'pendiente', 'completado', 'activo'
  final String? hijoId; // a quién está asignado
  final DateTime? fechaCreacion;
  final DateTime? fechaCompletado;

  Desafio({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.puntos,
    this.tiempoEstimadoMinutos = 0,
    this.estado = 'pendiente',
    this.hijoId,
    this.fechaCreacion,
    this.fechaCompletado,
  });

  /// Crea un Desafio desde el JSON que devuelve el backend
  factory Desafio.fromJson(Map<String, dynamic> json) {
    return Desafio(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      categoria: json['categoria'] ?? 'general',
      puntos: json['puntos'] != null ? (json['puntos'] as num).toInt() : 0,
      tiempoEstimadoMinutos: json['tiempo_estimado_minutos'] != null
          ? (json['tiempo_estimado_minutos'] as num).toInt()
          : 0,
      estado: json['estado'] ?? 'pendiente',
      hijoId: json['hijo_id']?.toString(),
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.tryParse(json['fecha_creacion'])
          : null,
      fechaCompletado: json['fecha_completado'] != null
          ? DateTime.tryParse(json['fecha_completado'])
          : null,
    );
  }

  /// Convierte el Desafio a JSON para enviarlo al backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'categoria': categoria,
      'puntos': puntos,
      'tiempo_estimado_minutos': tiempoEstimadoMinutos,
      'estado': estado,
      if (hijoId != null) 'hijo_id': hijoId,
      if (fechaCreacion != null) 'fecha_creacion': fechaCreacion!.toIso8601String(),
      if (fechaCompletado != null) 'fecha_completado': fechaCompletado!.toIso8601String(),
    };
  }

  Desafio copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    String? categoria,
    int? puntos,
    int? tiempoEstimadoMinutos,
    String? estado,
    String? hijoId,
    DateTime? fechaCreacion,
    DateTime? fechaCompletado,
  }) {
    return Desafio(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      puntos: puntos ?? this.puntos,
      tiempoEstimadoMinutos: tiempoEstimadoMinutos ?? this.tiempoEstimadoMinutos,
      estado: estado ?? this.estado,
      hijoId: hijoId ?? this.hijoId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaCompletado: fechaCompletado ?? this.fechaCompletado,
    );
  }

  bool get estaCompletado => estado.toLowerCase() == 'completado';
  bool get estaPendiente => estado.toLowerCase() == 'pendiente';
  bool get estaActivo => estado.toLowerCase() == 'activo';

  /// Texto del tiempo para mostrar en la UI: "5 min" o "Sin límite"
  String get tiempoTexto =>
      tiempoEstimadoMinutos > 0 ? '$tiempoEstimadoMinutos min' : 'Sin límite';

  @override
  String toString() => 'Desafio(id: $id, titulo: $titulo, estado: $estado)';
}