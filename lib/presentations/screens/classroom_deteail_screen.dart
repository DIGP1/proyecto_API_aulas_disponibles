import 'dart:convert';
import 'package:aulas_disponibles/presentations/api_request/api_request.dart';
import 'package:aulas_disponibles/presentations/models/aula.dart';
import 'package:aulas_disponibles/presentations/models/user.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
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
  int _currentImageIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  // --- NUEVO: Estado para la reserva actual del usuario ---
  int? _reservedClassroomId;
  String? _reservedClassroomName;

  @override
  void initState() {
    super.initState();
    _currentAula = widget.aula;
    _loadLocalData();
  }

  // --- MODIFICADO: Carga tanto el usuario como la reserva guardada ---
  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('currentUser');

    if (!mounted) return;
    setState(() {
      if (userJson != null) {
        _currentUser = User.fromJson(jsonDecode(userJson));
      }
      _reservedClassroomId = prefs.getInt('reservedClassroomId');
      _reservedClassroomName = prefs.getString('reservedClassroomName');
    });
  }

  // --- NUEVO: Guardar la reserva en SharedPreferences ---
  Future<void> _saveReservation(int id, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reservedClassroomId', id);
    await prefs.setString('reservedClassroomName', name);
    if (!mounted) return;
    setState(() {
      _reservedClassroomId = id;
      _reservedClassroomName = name;
    });
  }

  // --- NUEVO: Limpiar la reserva de SharedPreferences ---
  Future<void> _clearReservation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reservedClassroomId');
    await prefs.remove('reservedClassroomName');
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

  // --- NUEVO: Lógica central para manejar el botón de reserva/desocupar ---
  Future<void> _handleReservationLogic() async {
    // Escenario 1: El usuario ya tiene reservada ESTA aula
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

    // Escenario 2: El usuario tiene OTRA aula reservada
    if (_reservedClassroomId != null) {
      final confirmed = await _showConfirmationDialog(
        title: 'Cambiar Reserva',
        content:
            'Ya tienes reservada el aula "$_reservedClassroomName".\n\n¿Deseas desocuparla y reservar el ${_currentAula.nombre} en su lugar?',
        confirmText: 'Sí, Cambiar',
      );
      if (confirmed == true) {
        // Desocupa la antigua y luego reserva la nueva
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

    // Escenario 3: El usuario no tiene ninguna aula reservada
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

  // --- NUEVO: Widget de diálogo reutilizable ---
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

  @override
  Widget build(BuildContext context) {
    // --- MODIFICACIÓN: Lógica para el texto y estado del botón ---
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
        // --- MODIFICACIÓN: Lógica del Bottom Navigation Bar ---
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
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
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

    // --- MODIFICACIÓN: Si el aula está reservada por el usuario, se muestra como "Ocupada (Por ti)" ---
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
    return Scaffold(
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
        loadingBuilder: (context, event) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }
}
