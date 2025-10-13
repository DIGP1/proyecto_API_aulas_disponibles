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

  // Método factory para crear una instancia de User desde la respuesta JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user']['id'],
      nombre_completo: json['user']['nombre_completo'],
      email: json['user']['email'],
      telefono: json['user']['telefono'],
      departamento_id: json['user']['departamento_id'],
      estado: json['user']['estado'],
      token: json['token'],
      ultimo_acceso: json['user']['ultimo_acceso'],
      nombre_departamento: json['user']['nombre_departamento'],
      nombre_role: json['user']['nombre_role'],
    );
  }

  // Método para convertir User a JSON (útil si se necesitan guardar los datos localmente)
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
      'nombre_departamento': nombre_departamento,
      'nombre_role': nombre_role,
    };
  }
}
