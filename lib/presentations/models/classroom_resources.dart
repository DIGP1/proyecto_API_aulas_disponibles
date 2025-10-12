class ClassroomResources {
  final String recursoTipoNombre;
  final int idAula;
  final String nombreAula;
  final int recursoCantidad;
  final int classroomresourcesId;
  final String estado;
  final String observaciones;

  ClassroomResources({
    required this.recursoTipoNombre,
    required this.idAula,
    required this.nombreAula,
    required this.recursoCantidad,
    required this.classroomresourcesId,
    required this.estado,
    required this.observaciones,
  });

  // Método factory para crear una instancia desde la respuesta JSON
  factory ClassroomResources.fromJson(Map<String, dynamic> json) {
    return ClassroomResources(
      recursoTipoNombre: json['recurso_tipo_nombre'],
      idAula: json['id_aula'],
      nombreAula: json['nombre_aula'],
      recursoCantidad: json['recurso_cantidad'],
      classroomresourcesId: json['aula_recurso_id'],
      estado: json['estado'],
      observaciones: json['observaciones'],
    );
  }

  // Método para convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'recurso_tipo_nombre': recursoTipoNombre,
      'id_aula': idAula,
      'nombre_aula': nombreAula,
      'recurso_cantidad': recursoCantidad,
      'aula_recurso_id': classroomresourcesId,
      'estado': estado,
      'observaciones': observaciones,
    };
  }
}
