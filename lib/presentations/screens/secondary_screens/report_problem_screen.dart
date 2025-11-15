
import 'dart:io';
import 'package:aulas_disponibles/presentations/api_request/api_request.dart';
import 'package:aulas_disponibles/presentations/models/aula.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// Modelo para las categorías del reporte
class ReportCategory {
  final String value;
  final String label;
  final String descripcion;

  ReportCategory({
    required this.value,
    required this.label,
    required this.descripcion,
  });

  factory ReportCategory.fromJson(Map<String, dynamic> json) {
    return ReportCategory(
      value: json['value'],
      label: json['label'],
      descripcion: json['descripcion'],
    );
  }
}

class ReportProblemScreen extends StatefulWidget {
  final Aula aula;
  final String token;

  const ReportProblemScreen({
    super.key,
    required this.aula,
    required this.token,
  });

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final ApiRequest _apiRequest = ApiRequest();
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<ReportCategory> _categories = [];
  ReportCategory? _selectedCategory;
  File? _imageFile;
  bool _isLoadingCategories = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchReportCategories();
  }

  Future<void> _fetchReportCategories() async {
    try {
      final fetchedCategories = await _apiRequest.getReportCategories(widget.token);
      if (mounted) {
        setState(() {
          _categories = fetchedCategories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar las categorías: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80, // Comprime la imagen para reducir su tamaño
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

    Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      bool success = await _apiRequest.submitProblemReport(
        token: widget.token,
        classroomId: widget.aula.id,
        category: _selectedCategory!.value,
        description: _descriptionController.text,
        image: _imageFile,
        context: context,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Reporte enviado con éxito.' : 'Error al enviar el reporte.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          Navigator.of(context).pop();
        }
      }
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF9C241C);

    return GestureDetector(
      onHorizontalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
          Navigator.of(context).pop();
        }
      },
      child: 
        Scaffold(
          appBar: AppBar(
            title: const Text('Reportar un Problema', style: TextStyle(color: Colors.white)),
            backgroundColor: primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SafeArea(child: 
            _isLoadingCategories
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reporte para el aula:',
                          style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade700),
                        ),
                        Text(
                          widget.aula.nombre,
                          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<ReportCategory>(
                          value: _selectedCategory,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Categoría del Problema',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          hint: const Text('Selecciona una categoría'),
                          items: _categories.map((category) {
                            return DropdownMenuItem<ReportCategory>(
                              value: category,
                              child: Tooltip(
                                message: category.descripcion,
                                child: Text(category.label),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                          validator: (value) => value == null ? 'Debes seleccionar una categoría' : null,
                        ),
                        if (_selectedCategory != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 12.0, right: 12.0),
                            child: Text(
                              _selectedCategory!.descripcion,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: 'Descripción del Problema',
                            hintText: 'Proporciona más detalles sobre lo que encontraste...',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La descripción no puede estar vacía';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Adjuntar Evidencia (Opcional)',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        _buildImagePreview(),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                              : const Text('Enviar Reporte', style: TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
        ),
    );
  }

  Widget _buildImagePreview() {
    return 
    Center(
      child: GestureDetector(
        onTap: _takePicture,
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: _imageFile != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: () => setState(() => _imageFile = null),
                        ),
                      ),
                    )
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, size: 50, color: Colors.grey.shade600),
                    const SizedBox(height: 8),
                    Text('Tocar para tomar una foto', style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
        ),
      ),
    );
  }
}