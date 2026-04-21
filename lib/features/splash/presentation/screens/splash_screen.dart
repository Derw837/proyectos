import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:red_cristiana/core/notifications/local_notification_service.dart';
import 'package:red_cristiana/core/notifications/push_service.dart';
import 'package:red_cristiana/core/utils/network_status_helper.dart';
import 'package:red_cristiana/core/utils/user_helper.dart';
import 'package:red_cristiana/core/widgets/network_error_view.dart';
import 'package:red_cristiana/features/auth/presentation/screens/complete_google_signup_screen.dart';
import 'package:red_cristiana/features/auth/presentation/screens/login_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_pending_screen.dart';
import 'package:red_cristiana/features/home/presentation/screens/church_main_navigation_screen.dart';
import 'package:red_cristiana/features/home/presentation/screens/user_main_navigation_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _startupError;
  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _initNotifications() async {
    try {
      await LocalNotificationService.init();
    } catch (e) {
      debugPrint('Error LocalNotificationService.init: $e');
    }

    try {
      await PushService.init();
    } catch (e) {
      debugPrint('Error PushService.init: $e');
    }
  }

  Future<void> _startApp() async {
    if (mounted && _startupError != null) {
      setState(() {
        _startupError = null;
      });
    }

    await Future.delayed(const Duration(milliseconds: 700));

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    Map<String, dynamic>? profile;

    try {
      profile = await UserHelper.getProfile();
    } catch (e) {
      debugPrint('Error cargando perfil: $e');

      final cached = await UserHelper.getCachedProfile();
      if (cached != null && cached['id']?.toString() == user.id) {
        profile = cached;
      }
    }

    if (!mounted) return;

    if (profile == null) {
      final hasInternet = await NetworkStatusHelper.hasConnection();

      if (!hasInternet) {
        setState(() {
          _startupError = 'No pudimos abrir tu cuenta porque en este momento no hay internet y todavía no se ha podido validar tu perfil en este dispositivo.';
        });
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CompleteGoogleSignupScreen(),
        ),
      );
      return;
    }

    final role = profile['role']?.toString() ?? 'user';
    final approvalStatus =
        profile['approval_status']?.toString() ?? 'approved';

    Future.microtask(_initNotifications);

    if (role == 'church') {
      if (approvalStatus == 'approved') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ChurchMainNavigationScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ChurchPendingScreen(),
          ),
        );
      }
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const UserMainNavigationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_startupError != null) {
      return Scaffold(
        body: NetworkErrorView(
          message: _startupError!,
          onRetry: _startApp,
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