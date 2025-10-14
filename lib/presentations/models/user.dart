class User {
  final int id;
  final String nombre_completo;
  final String email;
  final String telefono;
  final int departamento_id;
  final String estado;
  final String ultimo_acceso;
  final String token;
  final String nombre_departamento;
  final String nombre_role;

  User({
    required this.id,
    required this.nombre_completo,
    required this.email,
    required this.telefono,
    required this.departamento_id,
    required this.estado,
    required this.token,
    required this.ultimo_acceso,
    required this.nombre_departamento,
    required this.nombre_role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final bool isApiStructure = json.containsKey('user') && json['user'] is Map;

    final userData = isApiStructure
        ? json['user'] as Map<String, dynamic>
        : json;

    return User(
      token: json['token'] ?? '',
      id: userData['id'] ?? 0,
      nombre_completo: userData['nombre_completo'] ?? '',
      email: userData['email'] ?? '',
      telefono: userData['telefono'] ?? '',
      departamento_id: userData['departamento_id'] ?? 0,
      estado: userData['estado'] ?? 'inactivo',
      ultimo_acceso: userData['ultimo_acceso'] ?? '',
      nombre_departamento: userData['departamento_nombre'] ?? 'No especificado',
      nombre_role: userData['role_nombre'] ?? 'Invitado',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre_completo': nombre_completo,
      'email': email,
      'telefono': telefono,
      'departamento_id': departamento_id,
      'estado': estado,
      'token': token,
      'ultimo_acceso': ultimo_acceso,
      'departamento_nombre': nombre_departamento,
      'role_nombre': nombre_role,
    };
  }
}
