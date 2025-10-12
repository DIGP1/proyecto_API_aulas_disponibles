class Aula {
  final int id;
  final String codigo;
  final String nombre;
  final int capacidadPupitres;
  final String ubicacion;
  final String qrCode;
  final String estado;
  final String createdAt;
  final String updatedAt;

  Aula({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.capacidadPupitres,
    required this.ubicacion,
    required this.qrCode,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
  });

  // Método factory para crear una instancia de Aula desde la respuesta JSON
  factory Aula.fromJson(Map<String, dynamic> json) {
    return Aula(
      id: json['id'],
      codigo: json['codigo'],
      nombre: json['nombre'],
      capacidadPupitres: json['capacidad_pupitres'],
      ubicacion: json['ubicacion'],
      qrCode: json['qr_code'],
      estado: json['estado'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  // Método para convertir Aula a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'capacidad_pupitres': capacidadPupitres,
      'ubicacion': ubicacion,
      'qr_code': qrCode,
      'estado': estado,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
