import 'package:aulas_disponibles/presentations/screens/authentication_screens/forgot_passwords_screens/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Aquí iría la lógica para llamar a la API y cambiar la contraseña
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cambiando contraseña...')));
      // Simula una llamada a la API y regresa
      Future.delayed(const Duration(seconds: 2), () {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña cambiada exitosamente.')),
        );
        Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final secondaryTextColor = const Color(0xFF6D6767);
    return GestureDetector(
      onHorizontalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
          Navigator.of(context).pop();
        }
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'Cambiar Contraseña',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF9C241C),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Actualiza tu contraseña',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Para proteger tu cuenta, asegúrate de que tu nueva contraseña sea segura.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  _buildPasswordField(
                    controller: _currentPasswordController,
                    label: 'Contraseña Actual',
                    isVisible: _isCurrentPasswordVisible,
                    toggleVisibility: () {
                      setState(
                        () => _isCurrentPasswordVisible =
                            !_isCurrentPasswordVisible,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(
                    controller: _newPasswordController,
                    label: 'Nueva Contraseña',
                    isVisible: _isNewPasswordVisible,
                    toggleVisibility: () {
                      setState(
                        () => _isNewPasswordVisible = !_isNewPasswordVisible,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirmar Nueva Contraseña',
                    isVisible: _isConfirmPasswordVisible,
                    toggleVisibility: () {
                      setState(
                        () => _isConfirmPasswordVisible =
                            !_isConfirmPasswordVisible,
                      );
                    },
                    validator: (value) {
                      if (value != _newPasswordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                            const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: GoogleFonts.interTight(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C241C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Guardar Cambios',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback toggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: toggleVisibility,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo no puede estar vacío';
        }
        if (validator != null) {
          return validator(value);
        }
        return null;
      },
    );
  }
}
