import 'package:aulas_disponibles/presentations/models/aula.dart';
import 'package:aulas_disponibles/presentations/models/classroom_resources.dart';
import 'package:flutter/material.dart';

// --- MODELO COMBINADO PARA LA UI ---
// Esta clase une un Aula con su lista de recursos para facilitar su manejo en la UI.
class AulaConRecursos {
  final Aula aula;
  final List<ClassroomResources> recursos;

  AulaConRecursos({required this.aula, required this.recursos});
}

// --- PANTALLA PRINCIPAL ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: Colors.white, body: HomeContent());
  }
}

// --- CONTENIDO DE LA PANTALLA DE INICIO (PLANTILLA VISUAL) ---
class HomeContent extends StatefulWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late TextEditingController _searchController;

  // --- LISTA DE DATOS DE PRUEBA ---
  final List<AulaConRecursos> originalAulas = [
    AulaConRecursos(
      aula: Aula(
        id: 1,
        codigo: 'AUX155',
        nombre: 'Aula 155',
        capacidadPupitres: 30,
        ubicacion: 'Edificio Minerva, Nivel 1',
        qrCode: 'QR1',
        estado: 'disponible',
        createdAt: '',
        updatedAt: '',
      ),
      recursos: [
        ClassroomResources(
          recursoTipoNombre: 'Pantalla inteligente',
          idAula: 1,
          nombreAula: 'Aula 155',
          recursoCantidad: 1,
          classroomresourcesId: 1,
          estado: 'bueno',
          observaciones: 'Buen estado',
        ),
        ClassroomResources(
          recursoTipoNombre: 'Proyector',
          idAula: 1,
          nombreAula: 'Aula 155',
          recursoCantidad: 1,
          classroomresourcesId: 2,
          estado: 'regular',
          observaciones: 'Lámpara con pocas horas de vida',
        ),
      ],
    ),
    AulaConRecursos(
      aula: Aula(
        id: 2,
        codigo: 'LAB-CS-01',
        nombre: 'Laboratorio de Cómputo 1',
        capacidadPupitres: 25,
        ubicacion: 'Edificio de Ingeniería, Nivel 2',
        qrCode: 'QR2',
        estado: 'ocupado',
        createdAt: '',
        updatedAt: '',
      ),
      recursos: [
        ClassroomResources(
          recursoTipoNombre: 'Computadoras',
          idAula: 2,
          nombreAula: 'Laboratorio de Cómputo 1',
          recursoCantidad: 25,
          classroomresourcesId: 3,
          estado: 'bueno',
          observaciones: 'Todas funcionales',
        ),
      ],
    ),
  ];

  // Lista que se mostrará y se filtrará
  late List<AulaConRecursos> aulasMostradas;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    aulasMostradas = originalAulas;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: _buildClassroomList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9C241C), Color(0xFFBF2E24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aulas Disponibles',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Encuentra un aula para tu clase',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ir a ver perfil...')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF9C241C)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar un aula por nombre...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value.isEmpty) {
                          aulasMostradas = originalAulas;
                        } else {
                          aulasMostradas = originalAulas
                              .where(
                                (item) => item.aula.nombre
                                    .toLowerCase()
                                    .contains(value.toLowerCase()),
                              )
                              .toList();
                        }
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune, color: Color(0xFF9C241C)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Abrir filtros...')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 15, 20, 5),
          child: Text(
            'Información de Aulas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        if (aulasMostradas.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No se encontraron resultados.'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: aulasMostradas.length,
            itemBuilder: (context, index) {
              final item = aulasMostradas[index];
              final aula = item.aula;
              final recursos = item.recursos;

              return GestureDetector(
                onTap: () {
                  print('Tocado el aula: ${aula.nombre}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Viendo: ${aula.nombre}')),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- INFORMACIÓN PRINCIPAL DEL AULA ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF9C241C).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.class_outlined,
                              color: Color(0xFF9C241C),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        aula.nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildAulaStatusTag(aula.estado),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  Icons.location_on_outlined,
                                  aula.ubicacion,
                                ),
                                const SizedBox(height: 4),
                                _buildInfoRow(
                                  Icons.people_alt_outlined,
                                  '${aula.capacidadPupitres} pupitres',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1),
                      // --- LISTA DE RECURSOS DEL AULA ---
                      const Text(
                        'Recursos del Aula:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Construye la lista de recursos para esta aula
                      ...recursos
                          .map((recurso) => _buildResourceRow(recurso))
                          .toList(),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // Widget para mostrar una fila de información (icono + texto)
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Widget para la etiqueta de estado del AULA
  Widget _buildAulaStatusTag(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'disponible':
        color = Colors.green;
        text = 'Disponible';
        icon = Icons.check_circle_outline;
        break;
      case 'ocupado':
        color = Colors.red;
        text = 'Ocupado';
        icon = Icons.cancel_outlined;
        break;
      default:
        color = Colors.grey;
        text = 'Desconocido';
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar una fila de un recurso específico
  Widget _buildResourceRow(ClassroomResources recurso) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              recurso.recursoTipoNombre,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Cant: ${recurso.recursoCantidad}',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(flex: 2, child: _buildStatusTag(recurso.estado)),
        ],
      ),
    );
  }

  // Widget para la etiqueta de estado del RECURSO
  Widget _buildStatusTag(String status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
