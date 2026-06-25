class AppBloqueada {
  final String id;
  final String hijoId;
  final String nombreApp;
  final String packageName; // ej: 'com.google.android.youtube'
  final bool requiereDesafio; // se desbloquea completando un desafío
  final DateTime? fechaCreacion;

  AppBloqueada({
    required this.id,
    required this.hijoId,
    required this.nombreApp,
    required this.packageName,
    this.requiereDesafio = true,
    this.fechaCreacion,
  });

  /// Crea una AppBloqueada desde el JSON que devuelve el backend
  /// El backend devuelve: id, hijo_id, nombre_app, package_name, requiere_desafio
  factory AppBloqueada.fromJson(Map<String, dynamic> json) {
    return AppBloqueada(
      id: json['id']?.toString() ?? '',
      hijoId: json['hijo_id']?.toString() ?? '',
      nombreApp: json['nombre_app'] ?? '',
      packageName: json['package_name'] ?? '',
      requiereDesafio:
          json['requiere_desafio'] == true || json['requiere_desafio'] == 1,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.tryParse(json['fecha_creacion'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hijo_id': hijoId,
      'nombre_app': nombreApp,
      'package_name': packageName,
      'requiere_desafio': requiereDesafio,
    };
  }

  Map<String, dynamic> toJsonUpdate() {
    return {
      'id': id,
      'hijo_id': hijoId,
      'nombre_app': nombreApp,
      'package_name': packageName,
      'requiere_desafio': requiereDesafio,
    };
  }

  AppBloqueada copyWith({
    String? id,
    String? hijoId,
    String? nombreApp,
    String? packageName,
    bool? requiereDesafio,
    DateTime? fechaCreacion,
  }) {
    return AppBloqueada(
      id: id ?? this.id,
      hijoId: hijoId ?? this.hijoId,
      nombreApp: nombreApp ?? this.nombreApp,
      packageName: packageName ?? this.packageName,
      requiereDesafio: requiereDesafio ?? this.requiereDesafio,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  @override
  String toString() =>
      'AppBloqueada(nombreApp: $nombreApp, package: $packageName, hijoId: $hijoId)';
}
