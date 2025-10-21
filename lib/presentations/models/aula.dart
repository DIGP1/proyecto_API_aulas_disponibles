import 'package:aulas_disponibles/presentations/models/classroom_resources.dart';

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
  final List<ClassroomResources> recursos;
  final List<String> images;

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
    required this.recursos,
    required this.images,
  });

  factory Aula.fromJson(Map<String, dynamic> json) {
    final List<dynamic> recursosJson = json['recursos'] ?? [];
    final List<ClassroomResources> recursosList = recursosJson
        .map((r) => ClassroomResources.fromJson(r))
        .toList();
    final List<dynamic> imagesJson = json['fotos'] ?? [];
    List<String> imagesList = imagesJson.map((i) => i.toString()).toList();

    // Si la lista de imágenes está vacía, añadimos placeholders
    if (imagesList.isEmpty) {
      imagesList = [
        'https://picsum.photos/seed/${json['id']}_1/800/600',
        'https://picsum.photos/seed/${json['id']}_2/800/600',
        'https://picsum.photos/seed/${json['id']}_3/800/600',
      ];
    }

    return Aula(
      id: json['id'] ?? 0,
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      capacidadPupitres: json['capacidad_pupitres'] ?? 0,
      ubicacion: json['ubicacion'] ?? '',
      qrCode: json['qr_code'] ?? '',
      estado: json['estado'] ?? 'desconocido',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      recursos: recursosList,
      images: imagesList,
    );
  }
}
