import 'dart:async';

import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/church_header_shell.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_dashboard_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_members_screen.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_profile_manage_screen.dart';
import 'package:red_cristiana/features/home/presentation/screens/home_feed_screen.dart';
import 'package:red_cristiana/features/notifications/data/notifications_service.dart';
import 'package:red_cristiana/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:red_cristiana/features/profile/presentation/screens/profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:red_cristiana/core/ads/ad_service.dart';
import 'package:red_cristiana/core/ads/ad_units.dart';

class ChurchMainNavigationScreen extends StatefulWidget {
  const ChurchMainNavigationScreen({super.key});

  @override
  State<ChurchMainNavigationScreen> createState() =>
      _ChurchMainNavigationScreenState();
}

class _ChurchMainNavigationScreenState extends State<ChurchMainNavigationScreen> {
  int currentIndex = 0;
  int unreadCount = 0;

  StreamSubscription<int>? _unreadSubscription;
  StreamSubscription<Map<String, dynamic>>? _latestNotificationSub;

  final List<Widget> screens = const [
    ChurchDashboardScreen(),
    ChurchHeaderShell(child: HomeFeedScreen()),
    ChurchMembersScreen(),
    ChurchProfileManageScreen(),
    ChurchHeaderShell(child: ProfileScreen()),
  ];

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

          final type = item['type']?.toString() ?? '';
          final title = item['title']?.toString() ?? 'Nueva notificación';
          final message = item['message']?.toString() ?? '';

          // Para no saturar, solo mostramos snackbar en tipos importantes
          const importantTypes = {'event', 'prayer_request', 'church_announcement'};
          if (!importantTypes.contains(type)) return;

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

  Future<void> _openSupportPage() async {
    final url = Uri.parse('https://pigoapp.com/#apoyo');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openDonate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF7F9FC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 22,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6EA),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  color: Color(0xFFE67E22),
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Apoya Red Cristiana ❤️',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tu apoyo nos ayuda a mantener la app gratuita para todos.\n\n'
                    'Puedes apoyarnos viendo un anuncio o haciendo una donación desde nuestra web.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);

                    final shown = await AdService.showRewardedAd(
                      adUnitId: AdUnits.rewardedSupport,
                      onRewardEarned: () {
                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '🙏 Gracias por apoyarnos viendo el anuncio',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );

                    if (!shown && mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'El anuncio aún no está listo. Inténtalo de nuevo en unos segundos.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.ondemand_video_rounded),
                  label: const Text('Apóyanos viendo un anuncio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openSupportPage,
                  icon: const Icon(Icons.favorite_outline_rounded),
                  label: const Text('Apóyanos con una donación'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _openStore() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF7F9FC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Apoya el proyecto 🙌',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              _supportProductCard(
                title: 'Apoyo 2',
                description: 'Ayuda básica para mantenimiento',
              ),
              _supportProductCard(
                title: 'Apoyo 5',
                description: 'Ayuda para servidores',
              ),
              _supportProductCard(
                title: 'Apoyo 10',
                description: 'Impulsa el crecimiento',
              ),
              _supportProductCard(
                title: 'Apoyo libre',
                description: 'Tú decides cuánto apoyar',
              ),
            ],
          ),
        );
      },
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

  Widget _supportProductCard({
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EAF3)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFE67E22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _openSupportPage,
            child: const Text('Apoyar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
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
            icon: Icon(Icons.public),
            selectedIcon: Icon(Icons.public),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Miembros',
          ),
          NavigationDestination(
            icon: Icon(Icons.church_outlined),
            selectedIcon: Icon(Icons.church),
            label: 'Iglesia',
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