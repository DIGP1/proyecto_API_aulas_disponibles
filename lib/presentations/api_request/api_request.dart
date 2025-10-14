import 'dart:convert';
import 'package:aulas_disponibles/presentations/models/aula.dart';
import 'package:aulas_disponibles/presentations/models/user.dart';
import 'package:aulas_disponibles/presentations/models/user_login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiRequest {
  static const String baseUrl = 'http://192.168.31.9:8000/api/';
  final http.Client client;
  ApiRequest({http.Client? client}) : client = client ?? http.Client();

  Future<User?> loginUser(user_login request, BuildContext context) async {
    try {
      final response = await client.post(
        Uri.parse('${baseUrl}login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        if (response.statusCode == 401) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario o contraseña incorrectos'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de conexión. Revisa tu internet.'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  // --- Login como Invitado ---
  Future<User?> loginAsGuest() async {
    try {
      final response = await client.post(
        Uri.parse('${baseUrl}login-as-guest'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        print("Error en login como invitado. Código: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Excepción en login como invitado: $e");
      return null;
    }
  }

  Future<List<Aula>> getAllClassrooms(String? token) async {
    // Verificación para asegurar que no se haga la llamada sin token
    if (token == null || token.isEmpty) {
      print("Error: No se puede obtener aulas sin un token de autenticación.");
      return [];
    }

    try {
      final response = await client.get(
        Uri.parse('${baseUrl}classrooms/get/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        if (decodedData.containsKey('data') && decodedData['data'] is List) {
          final List<dynamic> aulasJson = decodedData['data'];
          return aulasJson.map((json) => Aula.fromJson(json)).toList();
        }
        return [];
      } else {
        print("Error al obtener aulas. Código: ${response.statusCode}");
        print("Cuerpo de la respuesta: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Excepción al obtener aulas: $e");
      return [];
    }
  }

  Future<Aula?> getClassroomById(int id, String? token) async {
    if (token == null || token.isEmpty) {
      print(
        "Error: No se puede obtener el aula sin un token de autenticación.",
      );
      return null;
    }

    try {
      final response = await client.get(
        Uri.parse('${baseUrl}classrooms/get/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        if (decodedData.containsKey('data') && decodedData['data'] is Map) {
          final Map<String, dynamic> aulaJson = decodedData['data'];
          return Aula.fromJson(aulaJson);
        }
        return null;
      } else {
        print(
          "Error al obtener el aula por ID. Código: ${response.statusCode}",
        );
        print("Cuerpo de la respuesta: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Excepción al obtener el aula por ID: $e");
      return null;
    }
  }
}
