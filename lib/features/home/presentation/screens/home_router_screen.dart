import 'package:flutter/material.dart';
import 'package:red_cristiana/core/utils/user_helper.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_pending_screen.dart';
import 'package:red_cristiana/features/home/presentation/screens/church_main_navigation_screen.dart';
import 'package:red_cristiana/features/home/presentation/screens/user_main_navigation_screen.dart';
import 'package:red_cristiana/features/welcome/presentation/screens/welcome_screen.dart';

class HomeRouterScreen extends StatefulWidget {
  const HomeRouterScreen({super.key});

  @override
  State<HomeRouterScreen> createState() => _HomeRouterScreenState();
}

class _HomeRouterScreenState extends State<HomeRouterScreen> {
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await UserHelper.getProfile();

      if (!mounted) return;

      if (profile == null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
        );
        return;
      }

      final role = profile['role']?.toString() ?? 'user';
      final approvalStatus =
          profile['approval_status']?.toString() ?? 'approved';

      if (role == 'church' && approvalStatus == 'pending') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ChurchPendingScreen()),
              (route) => false,
        );
        return;
      }

      if (role == 'church' && approvalStatus == 'approved') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const ChurchMainNavigationScreen(),
          ),
              (route) => false,
        );
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const UserMainNavigationScreen(),
        ),
            (route) => false,
      );
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error cargando perfil: $e';
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