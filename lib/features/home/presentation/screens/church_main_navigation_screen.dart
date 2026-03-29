import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_dashboard_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_events_manage_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_profile_manage_screen.dart';
import 'package:red_cristiana/features/profile/presentation/screens/profile_screen.dart';

class ChurchMainNavigationScreen extends StatefulWidget {
  const ChurchMainNavigationScreen({super.key});

  @override
  State<ChurchMainNavigationScreen> createState() =>
      _ChurchMainNavigationScreenState();
}

class _ChurchMainNavigationScreenState extends State<ChurchMainNavigationScreen> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    ChurchDashboardScreen(),
    ChurchProfileManageScreen(),
    ChurchEventsManageScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Panel',
          ),
          NavigationDestination(
            icon: Icon(Icons.church_outlined),
            selectedIcon: Icon(Icons.church),
            label: 'Mi iglesia',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Eventos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Cuenta',
          ),
        ],
      ),
    );
  }
}