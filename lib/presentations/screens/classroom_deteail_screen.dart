import 'package:aulas_disponibles/presentations/screens/home.dart';
import 'package:flutter/material.dart';

class ClassroomDetailScreen extends StatelessWidget {
  final AulaConRecursos aulaConRecursos;

  const ClassroomDetailScreen({Key? key, required this.aulaConRecursos})
    : super(key: key);

  String _getTimeAgo(String dateString) {
    if (dateString.isEmpty) return '';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inSeconds < 5) {
        return 'justo ahora';
      } else if (difference.inMinutes < 1) {
        return 'hace ${difference.inSeconds} segundos';
      } else if (difference.inHours < 1) {
        return 'hace ${difference.inMinutes} minutos';
      } else if (difference.inDays < 1) {
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
    final aula = aulaConRecursos.aula;
    final recursos = aulaConRecursos.recursos;
    final bool isReservable = aula.estado.toLowerCase() == 'disponible';

    String buttonText;
    switch (aula.estado.toLowerCase()) {
      case 'disponible':
        buttonText = 'Reservar Aula';
        break;
      case 'ocupado':
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
          // --- MODIFICACIÓN: Título genérico en AppBar ---
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
                      'Reportar un problema con el ${aula.nombre}...',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvailabilityBanner(aula.estado),
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
                        // --- MODIFICACIÓN: Añadir nombre del aula a la tarjeta ---
                        _buildInfoRow(
                          Icons.class_outlined,
                          'Nombre',
                          aula.nombre,
                        ),
                        const Divider(),
                        _buildInfoRow(Icons.qr_code, 'Código', aula.codigo),
                        const Divider(),
                        _buildInfoRow(
                          Icons.location_on_outlined,
                          'Ubicación',
                          aula.ubicacion,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          Icons.people_alt_outlined,
                          'Capacidad',
                          '${aula.capacidadPupitres} pupitres',
                        ),
                        if (aula.updatedAt.isNotEmpty) ...[
                          const Divider(),
                          _buildInfoRow(
                            Icons.update,
                            'Actualizado',
                            _getTimeAgo(aula.updatedAt),
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
                      children: recursos.map((recurso) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // --- MODIFICACIÓN: Mostrar cantidad de recursos ---
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            recurso.recursoTipoNombre,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Cant: ${recurso.recursoCantidad}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (recurso.observaciones.isNotEmpty) ...[
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
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: isReservable
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reservando el ${aula.nombre}...'),
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
        ),
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
      case 'ocupado':
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
      default:
        color = Colors.red;
        text = 'Malo';
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
