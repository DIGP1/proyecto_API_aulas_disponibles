import 'package:aulas_disponibles/presentations/screens/home.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aulas Disponibles',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF9C241C),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9C241C)),
        useMaterial3: true,
      ),
      // Tu pantalla de inicio va aquí
      home: const HomeScreen(),
    );
  }
}
