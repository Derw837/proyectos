import 'package:flutter/material.dart';
import 'package:red_cristiana/features_tv/auth/tv_auth_gate.dart';

class AppTv extends StatelessWidget {
  const AppTv({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Red Cristiana TV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070B14),
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1E88FF),
          secondary: Color(0xFF6ED0FF),
          surface: Color(0xFF101826),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          headlineMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ),
      home: const TvAuthGate(),
    );
  }
}