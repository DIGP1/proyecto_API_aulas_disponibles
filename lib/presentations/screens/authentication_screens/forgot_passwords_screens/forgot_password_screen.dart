import 'package:aulas_disponibles/presentations/api_request/api_request.dart';
import 'package:aulas_disponibles/presentations/screens/authentication_screens/forgot_passwords_screens/verify_code_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final ApiRequest _apiRequest = ApiRequest(); 
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    if (_formKey.currentState!.validate()) {
      bool success = await _apiRequest.forgotPassword(_emailController.text, context);

      if (success && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VerifyCodeScreen(email: _emailController.text),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar el código. Inténtalo de nuevo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF9C241C);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      onHorizontalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFFFFF),
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF9C241C)),
        ),
        extendBodyBehindAppBar: true,
        key: scaffoldKey,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        body: 
        SafeArea(child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '¿Olvidaste tu contraseña?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
                    ),

                    Text(
                      'Ingresa tu correo electrónico',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Te enviaremos un código de verificación para restablecer tu contraseña.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.mail_outline, color: primaryColor),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty || !value.contains('@')) {
                          return 'Por favor ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _sendResetCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Enviar Código', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ))   
      ),
    );
  }
}