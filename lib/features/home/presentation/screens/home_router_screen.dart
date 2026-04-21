import 'package:flutter/material.dart';
import 'package:red_cristiana/core/utils/network_status_helper.dart';
import 'package:red_cristiana/core/utils/user_helper.dart';
import 'package:red_cristiana/features/auth/presentation/screens/church_registration_screen.dart';
import 'package:red_cristiana/features/auth/presentation/screens/complete_google_signup_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_pending_screen.dart';
import 'package:red_cristiana/features/home/presentation/screens/church_main_navigation_screen.dart';
import 'package:red_cristiana/features/home/presentation/screens/user_main_navigation_screen.dart';
import 'package:red_cristiana/features/welcome/presentation/screens/welcome_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeRouterScreen extends StatefulWidget {
  const HomeRouterScreen({super.key});

  @override
  State<HomeRouterScreen> createState() => _HomeRouterScreenState();
}

class _HomeRouterScreenState extends State<HomeRouterScreen> {
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _goTo(Widget page) async {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => page),
          (route) => false,
    );
  }

  Future<void> _loadProfile() async {
    try {
      final authUser = Supabase.instance.client.auth.currentUser;

      if (authUser == null) {
        await _goTo(const WelcomeScreen());
        return;
      }

      Map<String, dynamic>? profile;
      try {
        profile = await UserHelper.getProfile();
      } catch (_) {
        final cached = await UserHelper.getCachedProfile();
        if (cached != null && cached['id']?.toString() == authUser.id) {
          profile = cached;
        }
      }

      if (profile != null) {
        final role = profile['role']?.toString() ?? 'user';
        final approvalStatus =
            profile['approval_status']?.toString() ?? 'approved';

        if (role == 'church' && approvalStatus == 'pending') {
          await _goTo(const ChurchPendingScreen());
          return;
        }

        if (role == 'church' && approvalStatus == 'approved') {
          await _goTo(const ChurchMainNavigationScreen());
          return;
        }

        await _goTo(const UserMainNavigationScreen());
        return;
      }

      final metadata = authUser.userMetadata ?? {};
      final roleFromMeta = metadata['role']?.toString();
      final fullName = metadata['full_name']?.toString() ?? '';
      final signupSource = metadata['signup_source']?.toString();

      // Si viene de email y ya eligió rol, NO volver a preguntar.
      if (signupSource == 'email' && roleFromMeta == 'user') {
        await UserHelper.createUserProfileWithUserId(
          userId: authUser.id,
          fullName: fullName,
          country: '',
          city: '',
          sector: '',
        );
        await _goTo(const UserMainNavigationScreen());
        return;
      }

      if (signupSource == 'email' && roleFromMeta == 'church') {
        await UserHelper.createChurchProfilePlaceholderWithUserId(
          userId: authUser.id,
          fullName: fullName,
          country: '',
          city: '',
          sector: '',
        );
        await _goTo(
          ChurchRegistrationScreen(
            userId: authUser.id,
            userEmail: authUser.email ?? '',
          ),
        );
        return;
      }

      // Si viene de Google o no hay metadata, entonces sí preguntar.
      final hasInternet = await NetworkStatusHelper.hasConnection();
      if (!hasInternet) {
        setState(() {
          errorMessage = 'No pudimos abrir tu cuenta porque no hay internet y todavía no se ha podido validar tu perfil en este dispositivo.';
        });
        return;
      }

      await _goTo(const CompleteGoogleSignupScreen());
    } catch (e) {
      setState(() {
        errorMessage = 'No se pudo validar tu sesión en este momento. Revisa tu conexión y vuelve a intentarlo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}