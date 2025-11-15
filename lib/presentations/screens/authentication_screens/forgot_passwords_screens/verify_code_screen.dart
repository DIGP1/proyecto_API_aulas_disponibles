import 'dart:async';
import 'package:SICA/presentations/api_request/api_request.dart';
import 'package:SICA/presentations/screens/authentication_screens/forgot_passwords_screens/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;
  const VerifyCodeScreen({super.key, required this.email});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiRequest _apiRequest = ApiRequest();
  late Timer _timer;
  int _start = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    setState(() {
      _canResend = false;
      _start = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (_formKey.currentState!.validate()) {
      String? token = await _apiRequest.verifyResetCode(widget.email, _codeController.text, context);

      if (token != null && mounted) {
        _timer.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(email: widget.email, token: token),
          ),
        );
      }
    }
  }

  Future<void> _resendCode() async {
    bool success = await _apiRequest.forgotPassword(widget.email, context);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se ha reenviado un nuevo código.')),
      );
      startTimer();
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
                      'Verificación de Código',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Ingresa el código de 6 dígitos enviado a:',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 16),
                    ),
                    Text(
                      widget.email,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: GoogleFonts.inter(fontSize: 24, letterSpacing: 8),
                      decoration: InputDecoration(
                        labelText: 'Código de Verificación',
                        counterText: "",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.length != 6) {
                          return 'El código debe tener 6 dígitos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('¿No recibiste el código? ', style: GoogleFonts.inter()),
                        _canResend
                            ? TextButton(
                                onPressed: _resendCode,
                                child: Text('Reenviar', style: TextStyle(color: primaryColor)),
                              )
                            : Text('Reenviar en $_start s', style: GoogleFonts.inter(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Verificar', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            )
          ]
          )
      ),
    )
    );
  }
}