class ClassroomResources {
  final String nombre;
  final int cantidad;
  final int classroomresourcesId;
  final String estado;
  final String observaciones;

  ClassroomResources({
    required this.nombre,
    required this.cantidad,
    required this.classroomresourcesId,
    required this.estado,
    required this.observaciones,
  });

  // Método factory para crear una instancia desde la respuesta JSON
  factory ClassroomResources.fromJson(Map<String, dynamic> json) {
    return ClassroomResources(
      nombre: json['nombre'] ?? '',
      cantidad: json['cantidad'] ?? 0,
      classroomresourcesId: json['aula_recurso_id'] ?? 0,
      estado: json['estado'] ?? 'desconocido',
      observaciones: json['observaciones_recurso'] ?? '',
    );
  }

  // Método para convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'cantidad': cantidad,
      'aula_recurso_id': classroomresourcesId,
      'estado': estado,
      'observaciones_recurso': observaciones,
    };
  }
}
