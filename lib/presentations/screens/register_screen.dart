import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores para los campos de texto
  late TextEditingController _namesController;
  late TextEditingController _lastNamesController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  // Nodos de foco
  late FocusNode _namesFocusNode;
  late FocusNode _lastNamesFocusNode;
  late FocusNode _emailFocusNode;
  late FocusNode _phoneFocusNode;
  late FocusNode _passwordFocusNode;
  late FocusNode _confirmPasswordFocusNode;

  // Visibilidad de contraseñas
  late bool _passwordVisibility;
  late bool _confirmPasswordVisibility;

  // Valor para el Dropdown
  String? _careerValue;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _namesController = TextEditingController();
    _lastNamesController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _namesFocusNode = FocusNode();
    _lastNamesFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _confirmPasswordFocusNode = FocusNode();

    _passwordVisibility = false;
    _confirmPasswordVisibility = false;
  }

  @override
  void dispose() {
    _namesController.dispose();
    _lastNamesController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _namesFocusNode.dispose();
    _lastNamesFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Definimos los colores y estilos para no repetirlos
    const primaryColor = Color(0xFF660D04);
    const secondaryTextColor = Color(0xFF6D6767);

    // Estilo base para los campos de texto
    final inputDecoration = InputDecoration(
      labelStyle: GoogleFonts.inter(),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
      prefixIconColor: primaryColor,
    );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      onHorizontalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15.0,
                vertical: 10.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: primaryColor,
                          size: 30,
                        ),
                        onPressed: () {
                          // Acción para volver atrás, por ejemplo:
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Registro de usuario',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.interTight(
                        color: primaryColor,
                        fontSize: 35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Completa tus datos para registrarte',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: secondaryTextColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // --- Nombres ---
                    TextFormField(
                      controller: _namesController,
                      focusNode: _namesFocusNode,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Nombres',
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu nombre';
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- Apellidos ---
                    TextFormField(
                      controller: _lastNamesController,
                      focusNode: _lastNamesFocusNode,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Apellidos',
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tus apellidos';
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- Correo Electrónico ---
                    TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Correo electrónico',
                        prefixIcon: const Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu correo electrónico';
                        }

                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Por favor ingresa un correo electrónico válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- Teléfono ---
                    TextFormField(
                      controller: _phoneController,
                      focusNode: _phoneFocusNode,
                      keyboardType: TextInputType.phone,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Teléfono',
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu numero de telefono';
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'El teléfono solo debe contener números';
                        }
                        if (value.length > 8) {
                          return 'El teléfono no debe tener más de 8 dígitos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- Carrera (Dropdown) ---
                    DropdownButtonFormField<String>(
                      value: _careerValue,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Carrera',
                        prefixIcon: const Icon(Icons.school_outlined),
                      ),
                      items: ['Ingeniería de Sistemas', 'Medicina', 'Derecho']
                          .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          })
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _careerValue = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Selecciona tu carrera";
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- Contraseña ---
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: !_passwordVisibility,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisibility
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _passwordVisibility = !_passwordVisibility,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa una contraseña';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        if (!RegExp(r'[0-9]').hasMatch(value)) {
                          return 'La contraseña debe contener al menos un número';
                        }
                        if (value != _confirmPasswordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- Confirmar Contraseña ---
                    TextFormField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocusNode,
                      obscureText: !_confirmPasswordVisibility,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _confirmPasswordVisibility
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _confirmPasswordVisibility =
                                !_confirmPasswordVisibility,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa una contraseña';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        if (!RegExp(r'[0-9]').hasMatch(value)) {
                          return 'La contraseña debe contener al menos un número';
                        }
                        if (value != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // --- Botón Registrarse ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            print('¡Validación de registro exitosa!');
                            print('Nombres: ${_namesController.text}');
                            print('Apellidos: ${_lastNamesController.text}');
                            print('Email: ${_emailController.text}');
                            print('Teléfono: ${_phoneController.text}');
                            print('Carrera: $_careerValue');
                            print('Contraseña: ${_passwordController.text}');

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Registrando usuario...'),
                              ),
                            );
                          } else {
                            print('El formulario de registro tiene errores.');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Registrarse',
                          style: GoogleFonts.interTight(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
