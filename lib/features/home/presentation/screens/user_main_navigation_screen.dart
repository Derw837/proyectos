import 'dart:async';

import 'package:flutter/material.dart';
import 'package:red_cristiana/core/audio/audio_player_service.dart';
import 'package:red_cristiana/core/widgets/main_header.dart';
import 'package:red_cristiana/features/churches/presentation/screens/churches_screen.dart';
import 'package:red_cristiana/features/events/presentation/screens/events_screen.dart';
import 'package:red_cristiana/features/home/presentation/screens/home_feed_screen.dart';
import 'package:red_cristiana/features/live_tv/presentation/screens/live_tv_screen.dart';
import 'package:red_cristiana/features/media/presentation/screens/media_screen.dart';
import 'package:red_cristiana/features/notifications/data/notifications_service.dart';
import 'package:red_cristiana/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:red_cristiana/features/profile/presentation/screens/profile_screen.dart';
import 'package:red_cristiana/features/radios/presentation/screens/radios_screen.dart';

class UserMainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  final String? initialFeedChurchId;
  final String? initialFeedChurchName;
  final String initialFeedTab;

  final String? initialEventsChurchId;
  final String? initialEventsChurchName;

  const UserMainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.initialFeedChurchId,
    this.initialFeedChurchName,
    this.initialFeedTab = 'all',
    this.initialEventsChurchId,
    this.initialEventsChurchName,
  });

  @override
  State<UserMainNavigationScreen> createState() =>
      _UserMainNavigationScreenState();
}

class _UserMainNavigationScreenState extends State<UserMainNavigationScreen> {
  late int currentIndex;
  late List<Widget> screens;
  int unreadCount = 0;
  StreamSubscription<int>? _unreadSubscription;
  StreamSubscription<Map<String, dynamic>>? _latestNotificationSub;

  @override
  void initState() {
    super.initState();

    currentIndex = widget.initialIndex;

    screens = [
      HomeFeedScreen(
        initialChurchId: widget.initialFeedChurchId,
        initialChurchName: widget.initialFeedChurchName,
        initialTab: widget.initialFeedTab,
      ),
      const ChurchesScreen(),
      EventsScreen(
        initialChurchId: widget.initialEventsChurchId,
        initialChurchName: widget.initialEventsChurchName,
      ),
      const MediaScreen(),
      const RadiosScreen(),
      const LiveTvScreen(),
    ];

    AudioPlayerService.init();
    _loadUnreadCount();
    _listenUnreadCount();
    _listenIncomingNotifications();
  }

  @override
  void dispose() {
    _unreadSubscription?.cancel();
    _latestNotificationSub?.cancel();
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

  void _listenIncomingNotifications() {
    _latestNotificationSub =
        NotificationsService.latestIncomingNotificationStream().listen((item) {
          if (!mounted) return;

          final title = item['title']?.toString() ?? 'Nueva notificación';
          final message = item['message']?.toString() ?? '';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title\n$message'),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
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

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
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
                onProfile: _openProfile,
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
                icon: Icon(Icons.live_tv_outlined),
                selectedIcon: Icon(Icons.live_tv),
                label: 'TV',
              ),
            ],
          ),
        );
      },
    );
  }
}