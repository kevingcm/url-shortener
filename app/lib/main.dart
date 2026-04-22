import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(const ShortlyApp());
}

class ShortlyApp extends StatelessWidget {
  const ShortlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shortly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF667EEA)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
