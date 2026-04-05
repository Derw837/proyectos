import 'dart:async';

import 'package:flutter/material.dart';
import 'package:red_cristiana/core/widgets/main_header.dart';
import 'package:red_cristiana/features/notifications/data/notifications_service.dart';
import 'package:red_cristiana/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:red_cristiana/features/profile/presentation/screens/profile_screen.dart';

class ChurchHeaderShell extends StatefulWidget {
  final Widget child;

  const ChurchHeaderShell({
    super.key,
    required this.child,
  });

  @override
  State<ChurchHeaderShell> createState() => _ChurchHeaderShellState();
}

class _ChurchHeaderShellState extends State<ChurchHeaderShell> {
  int unreadCount = 0;
  StreamSubscription<int>? _unreadSubscription;
  StreamSubscription<Map<String, dynamic>>? _latestNotificationSub;

  @override
  void initState() {
    super.initState();
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
    _unreadSubscription = NotificationsService.unreadCountStream().listen((count) {
      if (!mounted) return;
      setState(() {
        unreadCount = count;
      });
    });
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            MainHeader(
              notificationCount: unreadCount,
              onNotifications: _openNotifications,
              onDonate: _openDonate,
              onStore: _openStore,
              onProfile: _openProfile,
            ),
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }
}