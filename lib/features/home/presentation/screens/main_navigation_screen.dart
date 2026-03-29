import 'package:flutter/material.dart';
import 'package:red_cristiana/features/events/presentation/screens/events_screen.dart';
import 'package:red_cristiana/features/home/presentation/screens/home_tab_screen.dart';
import 'package:red_cristiana/features/profile/presentation/screens/profile_screen.dart';
import 'package:red_cristiana/features/radios/presentation/screens/radios_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/churches_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    HomeTabScreen(),
    ChurchesScreen(),
    EventsScreen(),
    RadiosScreen(),
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
        height: 74,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.church_outlined),
            selectedIcon: Icon(Icons.church),
            label: 'Iglesias',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Eventos',
          ),
          NavigationDestination(
            icon: Icon(Icons.radio_outlined),
            selectedIcon: Icon(Icons.radio),
            label: 'Radios',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}