import 'dart:convert';
import 'dart:math';
import 'package:aulas_disponibles/presentations/api_request/api_request.dart';
import 'package:aulas_disponibles/presentations/models/aula.dart';
import 'package:aulas_disponibles/presentations/models/classroom_resources.dart';
import 'package:aulas_disponibles/presentations/models/user.dart';
import 'package:aulas_disponibles/presentations/screens/classroom_deteail_screen.dart';
import 'package:aulas_disponibles/presentations/screens/login_screen.dart';
import 'package:aulas_disponibles/presentations/screens/profile_screen.dart';
import 'package:aulas_disponibles/presentations/screens/qr_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiRequest _apiRequest = ApiRequest();
  late TextEditingController _searchController;

  bool _isLoading = true;
  bool _hasError = false;
  User? _currentUser;
  List<Aula> _originalAulas = [];
  List<Aula> _aulasMostradas = [];

  String? _selectedStatus;
  double _minCapacity = 0;
  bool _searchByLocation = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_filterAulas);
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterAulas);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString('currentUser', userJson);
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('currentUser');

      if (userJson != null) {
        _currentUser = User.fromJson(jsonDecode(userJson));
      } else {
        _currentUser = await _apiRequest.loginAsGuest();
        if (_currentUser != null) {
          await _saveUser(_currentUser!);
        }
      }

      if (_currentUser?.token.isNotEmpty ?? false) {
        final aulas = await _apiRequest.getAllClassrooms(_currentUser!.token);
        if (!mounted) return;
        setState(() {
          _originalAulas = aulas;
          _aulasMostradas = aulas;
          _isLoading = false;
          _hasError = false; // Asegurarse de que el error se limpie
        });
      } else {
        throw Exception('No se pudo obtener un token de autenticación.');
      }
    } catch (e) {
      print("Error en _loadInitialData: $e");
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    // Esta función es para el pull-to-refresh, no debe mostrar la pantalla de carga completa
    try {
      if (_currentUser?.token.isNotEmpty ?? false) {
        final aulas = await _apiRequest.getAllClassrooms(_currentUser!.token);
        if (!mounted) return;

        setState(() {
          _originalAulas = aulas;
          _aulasMostradas = aulas;
          _hasError = false;
          _searchController.clear();
          _selectedStatus = null;
          _minCapacity = 0;
        });
      } else {
        await _loadInitialData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al refrescar. Intente más tarde.')),
      );
    }
  }

  void _filterAulas() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _aulasMostradas = _originalAulas.where((aula) {
        final searchMatch =
            query.isEmpty ||
            (_searchByLocation
                ? aula.ubicacion.toLowerCase().contains(query)
                : (aula.nombre.toLowerCase().contains(query) ||
                      aula.codigo.toLowerCase().contains(query)));
        final statusMatch =
            _selectedStatus == null || aula.estado == _selectedStatus;
        final capacityMatch = aula.capacidadPupitres >= _minCapacity;
        return searchMatch && statusMatch && capacityMatch;
      }).toList();
    });
  }

  void _showFilterPanel() {
    final maxCap = _originalAulas.isNotEmpty
        ? _originalAulas.map((e) => e.capacidadPupitres).reduce(max).toDouble()
        : 150.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: FilterBottomSheet(
            currentStatus: _selectedStatus,
            currentCapacity: _minCapacity,
            currentSearchByLocation: _searchByLocation,
            maxCapacity: maxCap,
            onApplyFilters: (status, capacity, searchByLocation) {
              setState(() {
                _selectedStatus = status;
                _minCapacity = capacity;
                _searchByLocation = searchByLocation;
              });
              _filterAulas();
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF9C241C)),
              SizedBox(height: 20),
              Text('Cargando...'),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 24),
                const Text(
                  'Error de Conexión',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'No se pudieron cargar los datos. Por favor, revisa tu conexión a internet y vuelve a intentarlo.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _loadInitialData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C241C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: null,
        toolbarHeight: 171,
        flexibleSpace: _buildHeader(context),
        backgroundColor: const Color(0xFF9C241C),
      ),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF9C241C),
        child: HomeContent(aulasMostradas: _aulasMostradas),
      ),
      floatingActionButton: (_currentUser?.nombre_role != 'Invitado')
          ? FloatingActionButton(
              onPressed: () async {
                final String? qrCode = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QrScannerScreen(),
                  ),
                );
                if (qrCode != null && qrCode.isNotEmpty) {
                  try {
                    Aula? aula = await _apiRequest.getClassroomByQrCode(
                      qrCode,
                      _currentUser!.token,
                      context,
                    );
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ClassroomDetailScreen(aula: aula!),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error: No se pudo obtener el aula del código QR',
                        ),
                      ),
                    );
                  }
                }
              },
              backgroundColor: const Color(0xFF9C241C),
              child: const Icon(Icons.qr_code_scanner, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 12),
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
              (_currentUser?.nombre_role == 'Invitado')
                  ? TextButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                        if (result == true) {
                          await _loadInitialData();
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: const BorderSide(color: Colors.white),
                        ),
                      ),
                      child: const Text(
                        'Iniciar Sesión',
                        style: TextStyle(fontSize: 12),
                      ),
                    )
                  : Container(
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
                        onPressed: () async {
                          if (_currentUser != null) {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProfileScreen(user: _currentUser!),
                              ),
                            );
                            if (result == true) {
                              await _loadInitialData();
                            }
                          }
                        },
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 16),
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
                        hintText: _searchByLocation
                            ? 'Buscar por ubicación...'
                            : 'Buscar por nombre o código...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune, color: Color(0xFF9C241C)),
                    onPressed: _showFilterPanel,
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
  final List<Aula> aulasMostradas;
  const HomeContent({Key? key, required this.aulasMostradas}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (aulasMostradas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No se encontraron resultados para los filtros aplicados.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: aulasMostradas.length,
        itemBuilder: (context, index) {
          final aula = aulasMostradas[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassroomDetailScreen(aula: aula),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                  if (aula.recursos.isNotEmpty) ...[
                    const Divider(height: 24, thickness: 1),
                    const Text(
                      'Recursos del Aula:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...aula.recursos
                        .map((recurso) => _buildResourceRow(recurso))
                        .toList(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
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
      case 'ocupada':
        color = Colors.red;
        text = 'Ocupado';
        icon = Icons.cancel_outlined;
        break;
      case 'mantenimiento':
        color = Colors.orange;
        text = 'Mantenimiento';
        icon = Icons.settings_suggest_outlined;
        break;
      case 'inactiva':
        color = Colors.grey;
        text = 'Inactiva';
        icon = Icons.block_outlined;
        break;
      default:
        color = Colors.blueGrey;
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
              recurso.nombre,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Cant: ${recurso.cantidad}',
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
      case 'malo':
        color = Colors.red;
        text = 'Malo';
        break;
      default:
        color = Colors.blueGrey;
        text = status;
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

class FilterBottomSheet extends StatefulWidget {
  final String? currentStatus;
  final double currentCapacity;
  final bool currentSearchByLocation;
  final double maxCapacity;
  final Function(String?, double, bool) onApplyFilters;

  const FilterBottomSheet({
    Key? key,
    required this.currentStatus,
    required this.currentCapacity,
    required this.currentSearchByLocation,
    required this.maxCapacity,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  _FilterBottomSheetState createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? _status;
  late double _capacity;
  late bool _searchByLocation;

  @override
  void initState() {
    super.initState();
    _status = widget.currentStatus;
    _capacity = widget.currentCapacity;
    _searchByLocation = widget.currentSearchByLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          const Text('Estado', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8.0,
            children: [
              ChoiceChip(
                label: const Text('Disponible'),
                selected: _status == 'disponible',
                onSelected: (s) =>
                    setState(() => _status = s ? 'disponible' : null),
              ),
              ChoiceChip(
                label: const Text('Ocupada'),
                selected: _status == 'ocupada',
                onSelected: (s) =>
                    setState(() => _status = s ? 'ocupada' : null),
              ),
              ChoiceChip(
                label: const Text('Mantenimiento'),
                selected: _status == 'mantenimiento',
                onSelected: (s) =>
                    setState(() => _status = s ? 'mantenimiento' : null),
              ),
              ChoiceChip(
                label: const Text('Inactiva'),
                selected: _status == 'inactiva',
                onSelected: (s) =>
                    setState(() => _status = s ? 'inactiva' : null),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Capacidad Mínima: ${_capacity.toInt()}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _capacity,
            min: 0,
            max: widget.maxCapacity,
            divisions: widget.maxCapacity > 0 ? widget.maxCapacity.toInt() : 1,
            label: _capacity.round().toString(),
            onChanged: (v) => setState(() => _capacity = v),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text(
              'Buscar por Ubicación',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            value: _searchByLocation,
            onChanged: (v) => setState(() => _searchByLocation = v),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onApplyFilters(null, 0, false);
                  },
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onApplyFilters(
                    _status,
                    _capacity,
                    _searchByLocation,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C241C),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Aplicar Filtros'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
