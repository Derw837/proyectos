import 'package:flutter/material.dart';
import 'package:red_cristiana/features/splash/presentation/screens/splash_screen.dart';
import 'package:red_cristiana/navigator_key.dart';

class RedCristianaApp extends StatelessWidget {
  const RedCristianaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Red Cristiana',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}