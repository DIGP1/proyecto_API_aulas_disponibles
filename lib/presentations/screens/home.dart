import 'package:aulas_disponibles/presentations/models/aula.dart';
import 'package:aulas_disponibles/presentations/models/classroom_resources.dart';
import 'package:aulas_disponibles/presentations/screens/qr_scanner_screen.dart';
import 'package:flutter/material.dart';

// --- MODELO COMBINADO PARA LA UI ---
class AulaConRecursos {
  final Aula aula;
  final List<ClassroomResources> recursos;

  AulaConRecursos({required this.aula, required this.recursos});
}

// --- PANTALLA PRINCIPAL ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _searchController;
  late List<AulaConRecursos> aulasMostradas;

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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    aulasMostradas = originalAulas;
    _searchController.addListener(_filterAulas);
  }

  void _filterAulas() {
    final query = _searchController.text;
    setState(() {
      if (query.isEmpty) {
        aulasMostradas = originalAulas;
      } else {
        aulasMostradas = originalAulas
            .where(
              (item) =>
                  item.aula.nombre.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterAulas);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: HomeContent(aulasMostradas: aulasMostradas)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final String? qrCode = await Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (context) => const QrScannerScreen()),
          );
          if (qrCode != null && qrCode.isNotEmpty) {
            // Aquí puedes buscar el aula o hacer lo que necesites con el código QR
            //_searchController.text = qrCode;
            ScaffoldMessenger.of(context)
              ..removeCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text('Código QR escaneado: $qrCode')),
              );
          }
        },
        backgroundColor: const Color(0xFF9C241C),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/Idea_Logo_Proyecto.png',
                    height: 50,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Encuentra un aula para tu clase',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: IconButton(
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
              ),
            ],
          ),
          const SizedBox(height: 16),
          // --- SOLUCIÓN: Envolver la barra de búsqueda con un widget Material ---
          Material(
            color: Colors.transparent,
            child: Container(
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
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final List<AulaConRecursos> aulasMostradas;
  const HomeContent({Key? key, required this.aulasMostradas}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildClassroomList(context);
  }

  Widget _buildClassroomList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 5),
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
          ...aulasMostradas.map((item) {
            final aula = item.aula;
            final recursos = item.recursos;

            return GestureDetector(
              onTap: () {
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
                    const Text(
                      'Recursos del Aula:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...recursos
                        .map((recurso) => _buildResourceRow(recurso))
                        .toList(),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

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
        mainAxisSize: MainAxisSize.min,
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

  Widget _buildResourceRow(ClassroomResources recurso) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
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
          Expanded(flex: 2, child: _buildResourceStatusTag(recurso.estado)),
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
