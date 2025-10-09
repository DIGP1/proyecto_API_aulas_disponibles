import 'package:aulas_disponibles/presentations/models/user.dart';
import 'package:aulas_disponibles/presentations/models/user_login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiRequest {
  static const String baseUrl = 'http://';
  final http.Client client;
  ApiRequest({http.Client? client}) : client = client ?? http.Client();

  Future<User> loginUser(user_login request, BuildContext context) async {
    final response = await http.post(
      Uri.parse('${baseUrl}login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    var data = jsonDecode(response.body)['data'];
    print("Datos del usuario: ${data}");
    if (response.statusCode == 200) {
      if (data is Map<String, dynamic>) {
        var id_proyect = data['id_proyecto_asignado'];
        id_proyect ??= 0;
        data['user']['id_proyecto_asignado'] = id_proyect;
      }
      return User.fromJson(data);
    } else {
      if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Usuario o contraseña incorrectos',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
              textScaler: TextScaler.linear(1.5),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      print("Error en el login. Código: ${response.statusCode}");
      print("Cuerpo de la respuesta: ${response.body}");
      throw Exception('Error en el login');
    }
  }
}
