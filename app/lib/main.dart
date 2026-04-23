import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

void main() {
  runApp(const ShortlyApp());
}

class ShortlyApp extends StatelessWidget {
  const ShortlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF667EEA)),
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'Shortly',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        // Lexend across the whole app. google_fonts fetches the files on
        // first launch (cached after that); no .ttf bundling required.
        textTheme: GoogleFonts.lexendTextTheme(base.textTheme),
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      home: const HomeScreen(),
    );
  }
}
