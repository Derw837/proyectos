import 'package:flutter/material.dart';
import 'package:red_cristiana/features_tv/auth/tv_login_screen.dart';
import 'package:red_cristiana/features_tv/navigation/tv_main_navigation_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TvAuthGate extends StatelessWidget {
  const TvAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      initialData: AuthState(AuthChangeEvent.initialSession, supabase.auth.currentSession),
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;

        if (session != null) {
          return const TvMainNavigationScreen();
        }

        return const TvLoginScreen();
      },
    );
  }
}