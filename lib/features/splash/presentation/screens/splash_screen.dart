import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:red_cristiana/core/notifications/local_notification_service.dart';
import 'package:red_cristiana/core/notifications/push_service.dart';
import 'package:red_cristiana/core/utils/user_helper.dart';
import 'package:red_cristiana/features/auth/presentation/screens/login_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_dashboard_screen.dart';
import 'package:red_cristiana/features/home/presentation/screens/user_main_navigation_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _startApp() async {
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
    }

    final role = profile?['role']?.toString() ?? 'user';

    if (!mounted) return;

    if (role == 'church') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChurchDashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserMainNavigationScreen()),
      );
    }

    Future.microtask(() async {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}