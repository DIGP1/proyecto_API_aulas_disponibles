import 'dart:convert';
//import 'package:SICA/config/constants.dart';
import 'package:SICA/presentations/api_request/api_request.dart';
import 'package:SICA/presentations/models/aula.dart';
import 'package:SICA/presentations/models/user.dart';
import 'package:SICA/presentations/screens/secondary_screens/report_problem_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  int _currentImageIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  int? _reservedClassroomId;
  String? _reservedClassroomName;

  @override
  void initState() {
    super.initState();
    _currentAula = widget.aula;
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('currentUser');

    if (!mounted) return;

    User? currentUser;
    if (userJson != null) {
      currentUser = User.fromJson(jsonDecode(userJson));
    }

    // Cargar el mapa de reservas
    final reservationsJson = prefs.getString('userReservations');
    if (currentUser != null && reservationsJson != null) {
      final Map<String, dynamic> reservationsMap = jsonDecode(reservationsJson);
      final String userIdKey = currentUser.id.toString();

      // Verificar si el usuario actual tiene una reserva guardada
      if (reservationsMap.containsKey(userIdKey)) {
        final userReservation = reservationsMap[userIdKey] as Map<String, dynamic>;
        setState(() {
          _currentUser = currentUser;
          _reservedClassroomId = userReservation['id'];
          _reservedClassroomName = userReservation['name'];
        });
        return; // Salir si se encontró la reserva
      }
    }

    // Si no se encontró reserva o no hay usuario, establecer estado inicial
    setState(() {
      _currentUser = currentUser;
      _reservedClassroomId = null;
      _reservedClassroomName = null;
    });
  }

  Future<void> _saveReservation(int id, String name) async {
    if (_currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    final String userIdKey = _currentUser!.id.toString();

    // Obtener el mapa existente o crear uno nuevo
    final reservationsJson = prefs.getString('userReservations');
    Map<String, dynamic> reservationsMap = reservationsJson != null ? jsonDecode(reservationsJson) : {};

    // Añadir o actualizar la reserva para el usuario actual
    reservationsMap[userIdKey] = {'id': id, 'name': name};

    // Guardar el mapa actualizado como un string JSON
    await prefs.setString('userReservations', jsonEncode(reservationsMap));

    if (!mounted) return;
    setState(() {
      _reservedClassroomId = id;
      _reservedClassroomName = name;
    });
  }

  Future<void> _clearReservation() async {
    if (_currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    final String userIdKey = _currentUser!.id.toString();

    // Obtener el mapa existente
    final reservationsJson = prefs.getString('userReservations');
    if (reservationsJson == null) return; // No hay nada que limpiar

    Map<String, dynamic> reservationsMap = jsonDecode(reservationsJson);

    // Eliminar la reserva solo para el usuario actual
    if (reservationsMap.containsKey(userIdKey)) {
      reservationsMap.remove(userIdKey);
      // Guardar el mapa actualizado
      await prefs.setString('userReservations', jsonEncode(reservationsMap));
    }

    if (!mounted) return;
    setState(() {
      _reservedClassroomId = null;
      _reservedClassroomName = null;
    });
  }

  Future<void> _refreshClassroom() async {
    if (_currentUser?.token == null) return;
    final refreshedAula = await _apiRequest.getClassroomById(
      _currentAula.id,
      _currentUser!.token,
      context,
    );
    if (refreshedAula != null && mounted) {
      setState(() {
        _currentAula = refreshedAula;
      });
    }
  }

  Future<void> _handleReservationLogic() async {
    if (_currentUser?.token == null) return;

    if (_reservedClassroomId == _currentAula.id) {
      final confirmed = await _showConfirmationDialog(
        title: 'Desocupar Aula',
        content:
            '¿Estás seguro de que quieres desocupar el ${_currentAula.nombre}?',
        confirmText: 'Sí, Desocupar',
      );
      if (confirmed == true) {
        final success = await _apiRequest.changeClassroomStatus(
          _currentAula.id,
          'disponible',
          _currentUser!.token,
          context,
        );
        if (success) {
          await _clearReservation();
          await _refreshClassroom();
        }
      }
      return;
    }

    if (_reservedClassroomId != null) {
      final confirmed = await _showConfirmationDialog(
        title: 'Cambiar Reserva',
        content:
            'Ya tienes reservada el aula "$_reservedClassroomName".\n\n¿Deseas desocuparla y reservar el ${_currentAula.nombre} en su lugar?',
        confirmText: 'Sí, Cambiar',
      );
      if (confirmed == true) {
        final oldSuccess = await _apiRequest.changeClassroomStatus(
          _reservedClassroomId!,
          'disponible',
          _currentUser!.token,
          context,
        );
        if (oldSuccess) {
          final newSuccess = await _apiRequest.changeClassroomStatus(
            _currentAula.id,
            'ocupada',
            _currentUser!.token,
            context,
          );
          if (newSuccess) {
            await _saveReservation(_currentAula.id, _currentAula.nombre);
            await _refreshClassroom();
          }
        }
      }
      return;
    }

    if (_currentAula.estado.toLowerCase() == 'disponible') {
      final confirmed = await _showConfirmationDialog(
        title: 'Reservar Aula',
        content: '¿Confirmas que quieres reservar el ${_currentAula.nombre}?',
        confirmText: 'Sí, Reservar',
      );
      if (confirmed == true) {
        final success = await _apiRequest.changeClassroomStatus(
          _currentAula.id,
          'ocupada',
          _currentUser!.token,
          context,
        );
        if (success) {
          await _saveReservation(_currentAula.id, _currentAula.nombre);
          await _refreshClassroom();
        }
      }
    }
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(confirmText),
          ),
        ],
      ),
    );
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

  void _openImageGallery(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageGallery(
          images: _currentAula.images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _launchMapsApp(double lat, double lon) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
    );
    final Uri appleMapsUrl = Uri.parse('https://maps.apple.com/?q=$lat,$lon');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la aplicación de mapas'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String buttonText = 'Estado Desconocido';
    bool isButtonEnabled = false;
    Color buttonColor = Colors.grey;

    if (_reservedClassroomId == _currentAula.id) {
      buttonText = 'Desocupar Aula';
      isButtonEnabled = true;
      buttonColor = Colors.orange.shade700;
    } else {
      switch (_currentAula.estado.toLowerCase()) {
        case 'disponible':
          buttonText = 'Reservar Aula';
          isButtonEnabled = true;
          buttonColor = const Color(0xFF9C241C);
          break;
        case 'ocupada':
          buttonText = 'Aula Ocupada';
          isButtonEnabled = false;
          buttonColor = Colors.grey;
          break;
        case 'mantenimiento':
          buttonText = 'En Mantenimiento';
          isButtonEnabled = false;
          buttonColor = Colors.grey;
          break;
        case 'inactiva':
          buttonText = 'Aula Inactiva';
          isButtonEnabled = false;
          buttonColor = Colors.grey;
          break;
      }
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
                if (_currentUser != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ReportProblemScreen(
                        aula: _currentAula,
                        token: _currentUser!.token,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Debes iniciar sesión para reportar un problema.'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: _refreshClassroom,
            color: const Color(0xFF9C241C),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageCarousel(),
                  Padding(
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
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.location_on_outlined, color: Colors.grey.shade600),
                                    const SizedBox(width: 16),
                                    Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                      const Text(
                                        'Ubicación:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _currentAula.ubicacion,
                                        textAlign: TextAlign.justify,
                                        style: TextStyle(color: Colors.grey.shade800),
                                      ),
                                      ],
                                    ),
                                    ),
                                  ],
                                  ),
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
                        _buildMapPreview(),
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
                              children: _currentAula.recursos.isEmpty
                                  ? [
                                      const Text(
                                        'No hay recursos asignados a esta aula.',
                                      ),
                                    ]
                                  : _currentAula.recursos.map((recurso) {
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
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
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
                                                        color: Colors
                                                            .grey
                                                            .shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            _buildResourceStatusTag(
                                              recurso.estado,
                                            ),
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
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _currentUser?.nombre_role != 'Invitado'
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: isButtonEnabled
                        ? () => _handleReservationLogic()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
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

  Widget _buildMapPreview() {
    final lat = _currentAula.latitud;
    final lon = _currentAula.longitud;

    if (lat == null || lon == null) {
      return const SizedBox.shrink();
    }

    // --- MODIFICACIÓN: Reemplazar todo el widget con GoogleMap ---
    final LatLng initialPosition = LatLng(lat, lon);
    final Set<Marker> markers = {
      Marker(
        markerId: MarkerId(_currentAula.id.toString()),
        position: initialPosition,
        infoWindow: InfoWindow(
          title: _currentAula.nombre,
          snippet: _currentAula.ubicacion,
        ),
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Ubicación en el Mapa',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 250, // Define una altura para el contenedor del mapa
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 17.0, // Nivel de zoom inicial
              ),
              markers: markers,
              onTap: (_) => _launchMapsApp(
                lat,
                lon,
              ), // Permite abrir la app de mapas al tocar
              mapType: MapType.normal,
              myLocationButtonEnabled:
                  false, // Opcional: oculta el botón de "mi ubicación"
              zoomControlsEnabled:
                  true, // Muestra los controles de zoom nativos
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageCarousel() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: _currentAula.images.length,
          itemBuilder: (context, index, realIndex) {
            final imageUrl = _currentAula.images[index];
            return GestureDetector(
              onTap: () => _openImageGallery(index),
              child: Hero(
                tag: imageUrl,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  color: Colors.black,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 250,
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            onPageChanged: (index, reason) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
        ),
        Positioned(
          bottom: 10.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _currentAula.images.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => _carouselController.animateToPage(entry.key),
                child: Container(
                  width: 12.0,
                  height: 12.0,
                  margin: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 4.0,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black)
                            .withOpacity(
                              _currentImageIndex == entry.key ? 0.9 : 0.4,
                            ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityBanner(String status) {
    Color color;
    String text;
    IconData icon;

    if (_reservedClassroomId == _currentAula.id) {
      status = 'ocupada';
    }

    switch (status.toLowerCase()) {
      case 'disponible':
        color = Colors.green;
        text = 'DISPONIBLE';
        icon = Icons.check_circle_outline;
        break;
      case 'ocupada':
        color = Colors.red;
        text = _reservedClassroomId == _currentAula.id
            ? 'OCUPADA (POR TI)'
            : 'OCUPADA';
        icon = _reservedClassroomId == _currentAula.id
            ? Icons.person_pin
            : Icons.cancel_outlined;
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

class FullScreenImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageGallery({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  _FullScreenImageGalleryState createState() => _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<FullScreenImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  void onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity!.abs() > 100) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            '${_currentIndex + 1} / ${widget.images.length}',
            style: const TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: PhotoViewGallery.builder(
          pageController: _pageController,
          itemCount: widget.images.length,
          onPageChanged: onPageChanged,
          builder: (context, index) {
            final imageUrl = widget.images[index];
            return PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
            );
          },
          loadingBuilder: (context, event) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
