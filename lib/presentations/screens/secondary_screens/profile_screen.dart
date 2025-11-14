import 'dart:convert';

import 'package:aulas_disponibles/presentations/api_request/api_request.dart';
import 'package:aulas_disponibles/presentations/models/user.dart';
import 'package:aulas_disponibles/presentations/screens/authentication_screens/change_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatelessWidget {
  final User user;

  ProfileScreen({Key? key, required this.user}) : super(key: key);

  final ApiRequest _apiRequest = ApiRequest();

  Future<void> _clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUser');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
          Navigator.of(context).pop();
        }
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'Mi Perfil',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF9C241C),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // --- Tarjeta de Información Principal ---
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: Color(0xFF9C241C),
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.nombre_completo,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.nombre_role,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Tarjeta de Detalles de Contacto y Departamento ---
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildInfoTile(Icons.email_outlined, 'Email', user.email),
                      const Divider(height: 1),
                      _buildInfoTile(
                        Icons.phone_outlined,
                        'Teléfono',
                        user.telefono,
                      ),
                      const Divider(height: 1),
                      _buildInfoTile(
                        Icons.business_outlined,
                        'Departamento',
                        user.nombre_departamento,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // --- Botones de Acción ---
                _buildActionButton(
                  context,
                  icon: Icons.lock_outline,
                  text: 'Cambiar Contraseña',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // --- MODIFICACIÓN: Lógica de onTap para cerrar sesión ---
                _buildActionButton(
                  context,
                  icon: Icons.logout,
                  text: 'Cerrar Sesión',
                  color: Colors.red.shade700,
                  onTap: () async {
                    final bool? confirmed = await _showLogoutConfirmation(
                      context,
                    );

                    if (confirmed == true) {
                      final bool apiLogoutSuccess = await _apiRequest.logout(
                        user.token,
                      );

                      if (!context.mounted) return;

                      if (apiLogoutSuccess) {
                        await _clearUserSession();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sesión cerrada exitosamente.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.of(context).pop(true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Error al cerrar sesión. Intente más tarde.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF9C241C)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade800)),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color? color,
  }) {
    final actionColor = color ?? const Color(0xFF9C241C);
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(text, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: actionColor,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }

  Future<bool?> _showLogoutConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                // Cierra el diálogo y devuelve 'false'
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text(
                'Sí, Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                // Cierra el diálogo y devuelve 'true'
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
}
