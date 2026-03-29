import 'dart:async';

import 'package:flutter/material.dart';
import 'package:red_cristiana/core/audio/audio_player_service.dart';
import 'package:red_cristiana/core/widgets/main_header.dart';
import 'package:red_cristiana/features/churches/presentation/screens/churches_screen.dart';
import 'package:red_cristiana/features/events/presentation/screens/events_screen.dart';
import 'package:red_cristiana/features/home/presentation/screens/home_feed_screen.dart';
import 'package:red_cristiana/features/media/presentation/screens/media_screen.dart';
import 'package:red_cristiana/features/notifications/data/notifications_service.dart';
import 'package:red_cristiana/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:red_cristiana/features/profile/presentation/screens/profile_screen.dart';
import 'package:red_cristiana/features/radios/presentation/screens/radios_screen.dart';

class UserMainNavigationScreen extends StatefulWidget {
  const UserMainNavigationScreen({super.key});

  @override
  State<UserMainNavigationScreen> createState() =>
      _UserMainNavigationScreenState();
}

class _UserMainNavigationScreenState extends State<UserMainNavigationScreen> {
  int currentIndex = 0;
  int unreadCount = 0;
  StreamSubscription<int>? _unreadSubscription;

  final List<Widget> screens = const [
    HomeFeedScreen(),
    ChurchesScreen(),
    EventsScreen(),
    MediaScreen(),
    RadiosScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    AudioPlayerService.init();
    _loadUnreadCount();
    _listenUnreadCount();
  }

  @override
  void dispose() {
    _unreadSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await NotificationsService.getUnreadCount();
      if (!mounted) return;
      setState(() {
        unreadCount = count;
      });
    } catch (_) {}
  }

  void _listenUnreadCount() {
    _unreadSubscription = NotificationsService.unreadCountStream().listen(
          (count) {
        if (!mounted) return;
        setState(() {
          unreadCount = count;
        });
      },
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );

    await _loadUnreadCount();
  }

  void _openDonate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sección Donar próximamente')),
    );
  }

  void _openStore() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tienda próximamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AudioPlayerService.isPlayingNotifier,
      builder: (context, isPlaying, _) {
        return Scaffold(
          body: Column(
            children: [
              MainHeader(
                notificationCount: unreadCount,
                onNotifications: _openNotifications,
                onDonate: _openDonate,
                onStore: _openStore,
              ),
              Expanded(
                child: IndexedStack(
                  index: currentIndex,
                  children: screens,
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              const NavigationDestination(
                icon: Icon(Icons.church_outlined),
                selectedIcon: Icon(Icons.church),
                label: 'Iglesias',
              ),
              const NavigationDestination(
                icon: Icon(Icons.event_outlined),
                selectedIcon: Icon(Icons.event),
                label: 'Eventos',
              ),
              const NavigationDestination(
                icon: Icon(Icons.ondemand_video_outlined),
                selectedIcon: Icon(Icons.ondemand_video),
                label: 'Videos',
              ),
              NavigationDestination(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      isPlaying ? Icons.graphic_eq : Icons.radio_outlined,
                    ),
                    if (isPlaying)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                selectedIcon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      isPlaying ? Icons.graphic_eq : Icons.radio,
                    ),
                    if (isPlaying)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                label: isPlaying ? 'Sonando' : 'Radios',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        );
      },
    );
  }
}