import 'dart:async';

import 'package:flutter/material.dart';
import 'package:red_cristiana/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:red_cristiana/features/splash/presentation/screens/splash_screen.dart';
import 'package:red_cristiana/navigator_key.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RedCristianaApp extends StatefulWidget {
  const RedCristianaApp({super.key});

  @override
  State<RedCristianaApp> createState() => _RedCristianaAppState();
}

class _RedCristianaAppState extends State<RedCristianaApp> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _openedRecoveryScreen = false;

  @override
  void initState() {
    super.initState();

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
          final event = data.event;

          if (event == AuthChangeEvent.passwordRecovery) {
            if (_openedRecoveryScreen) return;
            _openedRecoveryScreen = true;

            appNavigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
                  (route) => false,
            );
            return;
          }

          if (event == AuthChangeEvent.signedIn) {
            if (_openedRecoveryScreen) return;

            appNavigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
            );
            return;
          }

          if (event == AuthChangeEvent.signedOut) {
            _openedRecoveryScreen = false;
          }
        });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

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