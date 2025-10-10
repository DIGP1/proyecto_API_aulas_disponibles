import 'package:aulas_disponibles/presentations/api_request/api_request.dart';
import 'package:aulas_disponibles/presentations/models/user.dart';
import 'package:aulas_disponibles/presentations/models/user_login.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aulas_disponibles/presentations/screens/register_screen.dart';

// Renombramos el widget para mayor claridad
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. Movemos los controladores y el estado aquí
  late TextEditingController _emailController;
  late FocusNode _emailFocusNode;
  late TextEditingController _passwordController;
  late FocusNode _passwordFocusNode;
  late bool _passwordVisibility;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  user_login? _userLogin;
  User? _user;
  final ApiRequest _apiRequest = ApiRequest();

  @override
  void initState() {
    super.initState();
    // 2. Inicializamos todo en initState
    _emailController = TextEditingController();
    _emailFocusNode = FocusNode();
    _passwordController = TextEditingController();
    _passwordFocusNode = FocusNode();
    _passwordVisibility = false;
  }

  @override
  void dispose() {
    // 3. Hacemos dispose para liberar memoria
    _emailController.dispose();
    _emailFocusNode.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Definimos los colores y estilos para no repetirlos
    final primaryColor = Color(0xFF660D04);
    final secondaryTextColor = Color(0xFF6D6767);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            // Usamos SingleChildScrollView para evitar overflow
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15.0,
                vertical: 20.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      // Reemplaza la imagen de prueba con tu logo
                      child: Image.asset(
                        'assets/images/logo.png', // Asegúrate que esta ruta es correcta
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.school,
                              size: 80,
                              color: primaryColor,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '¡Bienvenido!',
                      style: GoogleFonts.interTight(
                        color: primaryColor,
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Inicia sesión para encontrar aulas disponibles en la Facultad Multidiciplinaria Oriental',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Column(
                      children: [
                        // --- Campo de Correo Electrónico ---
                        TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            labelStyle: GoogleFonts.inter(),
                            filled: true,
                            fillColor: Colors.grey[100],
                            prefixIcon: Icon(
                              Icons.mail_outline,
                              color: primaryColor,
                              size: 24,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu correo electrónico';
                            }
                            // Expresión regular simple para validar email
                            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                            if (!emailRegex.hasMatch(value)) {
                              return 'Por favor ingresa un correo electrónico válido';
                            }
                            return null;
                          },
                          style: GoogleFonts.inter(),
                        ),
                        const SizedBox(height: 30),
                        // --- Campo de Contraseña ---
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: !_passwordVisibility,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            labelStyle: GoogleFonts.inter(),
                            filled: true,
                            fillColor: Colors.grey[100],
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: primaryColor,
                              size: 24,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisibility
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 22,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisibility = !_passwordVisibility;
                                });
                              },
                            ),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu contraseña';
                            }
                            if (value.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                          style: GoogleFonts.inter(),
                        ),
                        const SizedBox(height: 30),
                        // --- Botón Iniciar Sesión (Reemplazado con ElevatedButton) ---
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                String _correo1 = _emailController!.text
                                    .substring(0, 7)
                                    .toLowerCase();
                                String _correo2 = _emailController!.text
                                    .substring(7)
                                    .toLowerCase();
                                _userLogin = user_login(
                                  email: _correo1 + _correo2,
                                  password: _passwordController.text,
                                );
                                _user = await _apiRequest.loginUser(
                                  _userLogin!,
                                  context,
                                );
                                if (_user != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Inicio de sesión exitoso",
                                        style: TextStyle(color: Colors.white),
                                        textAlign: TextAlign.center,
                                        textScaler: TextScaler.linear(1.5),
                                      ),
                                      backgroundColor: Color.fromARGB(
                                        255,
                                        31,
                                        145,
                                        35,
                                      ),
                                    ),
                                  );
                                  await Future.delayed(
                                    const Duration(seconds: 2),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Iniciar sesión',
                              style: GoogleFonts.interTight(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        // --- Botón Olvidaste Contraseña (Reemplazado con TextButton) ---
                        TextButton(
                          onPressed: () {
                            print("Boton olvidaste tu contraseña presionado");
                          },
                          child: Text(
                            '¿Olvidaste tu contraseña?',
                            style: GoogleFonts.interTight(
                              color: secondaryTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // --- Botón Crear Cuenta (Reemplazado con OutlinedButton) ---
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              'Crear nueva cuenta',
                              style: GoogleFonts.interTight(
                                color: primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
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
