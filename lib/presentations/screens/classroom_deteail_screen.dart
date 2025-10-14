import 'dart:convert';
import 'package:aulas_disponibles/presentations/api_request/api_request.dart';
import 'package:aulas_disponibles/presentations/models/aula.dart';
import 'package:aulas_disponibles/presentations/models/user.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClassroomDetailScreen extends StatefulWidget {
  final Aula aula;

  const ClassroomDetailScreen({Key? key, required this.aula}) : super(key: key);

  @override
  State<ClassroomDetailScreen> createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen> {
  final ApiRequest _apiRequest = ApiRequest();
  late Aula _currentAula;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentAula = widget.aula;
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('currentUser');
    if (userJson != null) {
      if (!mounted) return;
      setState(() {
        _currentUser = User.fromJson(jsonDecode(userJson));
      });
    }
  }

  Future<void> _refreshClassroom() async {
    if (_currentUser?.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo autenticar para refrescar.')),
      );
      return;
    }

    final refreshedAula = await _apiRequest.getClassroomById(
      _currentAula.id,
      _currentUser!.token,
      context,
    );

    if (refreshedAula != null && mounted) {
      setState(() {
        _currentAula = refreshedAula;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar los datos del aula.'),
        ),
      );
    }
  }

  String _getTimeAgo(String dateString) {
    if (dateString.isEmpty) return 'no disponible';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inSeconds < 5) return 'justo ahora';
      if (difference.inMinutes < 1)
        return 'hace ${difference.inSeconds} segundos';
      if (difference.inHours < 1) return 'hace ${difference.inMinutes} minutos';
      if (difference.inDays < 1) {
        final hours = difference.inHours;
        final minutes = difference.inMinutes % 60;
        return 'hace ${hours}h y ${minutes}m';
      } else {
        final days = difference.inDays;
        final hours = difference.inHours % 24;
        return 'hace ${days}d y ${hours}h';
      }
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final recursos = _currentAula.recursos;
    final bool isReservable = _currentAula.estado.toLowerCase() == 'disponible';

    String buttonText;
    switch (_currentAula.estado.toLowerCase()) {
      case 'disponible':
        buttonText = 'Reservar Aula';
        break;
      case 'ocupada':
        buttonText = 'Aula Ocupada';
        break;
      case 'mantenimiento':
        buttonText = 'En Mantenimiento';
        break;
      case 'inactiva':
        buttonText = 'Aula Inactiva';
        break;
      default:
        buttonText = 'Estado Desconocido';
    }

    return GestureDetector(
      onHorizontalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Detalles del Aula',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF9C241C),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.flag_outlined, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Reportar un problema con el ${_currentAula.nombre}...',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshClassroom,
            color: const Color(0xFF9C241C),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvailabilityBanner(_currentAula.estado),
                    const SizedBox(height: 24),
                    Text(
                      'Información General',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              Icons.class_outlined,
                              'Nombre',
                              _currentAula.nombre,
                            ),
                            const Divider(),
                            _buildInfoRow(
                              Icons.qr_code,
                              'Código',
                              _currentAula.codigo,
                            ),
                            const Divider(),
                            _buildInfoRow(
                              Icons.location_on_outlined,
                              'Ubicación',
                              _currentAula.ubicacion,
                            ),
                            const Divider(),
                            _buildInfoRow(
                              Icons.people_alt_outlined,
                              'Capacidad',
                              '${_currentAula.capacidadPupitres} pupitres',
                            ),
                            if (_currentAula.updatedAt.isNotEmpty) ...[
                              const Divider(),
                              _buildInfoRow(
                                Icons.update,
                                'Actualizado',
                                _getTimeAgo(_currentAula.updatedAt),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Recursos del Aula',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: recursos.isEmpty
                              ? [
                                  const Text(
                                    'No hay recursos asignados a esta aula.',
                                  ),
                                ]
                              : recursos.map((recurso) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10.0,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      recurso.nombre,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    'Cant: ${recurso.cantidad}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (recurso
                                                  .observaciones
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  recurso.observaciones,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        _buildResourceStatusTag(recurso.estado),
                                      ],
                                    ),
                                  );
                                }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: _currentUser?.nombre_departamento != 'Guest'
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: isReservable
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Reservando el ${_currentAula.nombre}...',
                                ),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isReservable
                          ? const Color(0xFF9C241C)
                          : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildAvailabilityBanner(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'disponible':
        color = Colors.green;
        text = 'DISPONIBLE';
        icon = Icons.check_circle_outline;
        break;
      case 'ocupada':
        color = Colors.red;
        text = 'OCUPADO';
        icon = Icons.cancel_outlined;
        break;
      case 'mantenimiento':
        color = Colors.orange;
        text = 'MANTENIMIENTO';
        icon = Icons.settings_suggest_outlined;
        break;
      case 'inactiva':
        color = Colors.grey;
        text = 'INACTIVA';
        icon = Icons.block_outlined;
        break;
      default:
        color = Colors.grey;
        text = 'DESCONOCIDO';
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceStatusTag(String status) {
    Color color;
    String text;
    switch (status.toLowerCase()) {
      case 'bueno':
        color = Colors.green;
        text = 'Bueno';
        break;
      case 'regular':
        color = Colors.orange;
        text = 'Regular';
        break;
      case 'malo':
        color = Colors.red;
        text = 'Malo';
        break;
      default:
        color = Colors.blueGrey;
        text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
