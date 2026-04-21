import 'package:flutter/material.dart';
import 'package:red_cristiana/features_tv/home/tv_home_screen.dart';
import 'package:red_cristiana/features_tv/live_tv/tv_live_screen.dart';
import 'package:red_cristiana/features_tv/profile/tv_profile_screen.dart';
import 'package:red_cristiana/features_tv/radios/tv_radios_screen.dart';
import 'package:red_cristiana/features_tv/support/tv_support_screen.dart';
import 'package:red_cristiana/features_tv/videos/tv_videos_screen.dart';
import 'package:red_cristiana/features_tv/widgets/tv_pressable.dart';

class TvMainNavigationScreen extends StatefulWidget {
  const TvMainNavigationScreen({super.key});

  @override
  State<TvMainNavigationScreen> createState() => _TvMainNavigationScreenState();
}

class _TvMainNavigationScreenState extends State<TvMainNavigationScreen> {
  int _selectedIndex = 0;

  final List<_TvMenuItem> _items = const [
    _TvMenuItem(label: 'Inicio', icon: Icons.home_rounded),
    _TvMenuItem(label: 'Videos', icon: Icons.ondemand_video_rounded),
    _TvMenuItem(label: 'Radios', icon: Icons.radio_rounded),
    _TvMenuItem(label: 'TV en vivo', icon: Icons.live_tv_rounded),
    _TvMenuItem(label: 'Perfil', icon: Icons.person_rounded),
    _TvMenuItem(label: 'Apóyanos', icon: Icons.favorite_rounded),
  ];

  List<Widget> get _screens => const [
    TvHomeScreen(),
    TvVideosScreen(),
    TvRadiosScreen(),
    TvLiveScreen(),
    TvProfileScreen(),
    TvSupportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0C1220),
                  Color(0xFF101A2B),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                right: BorderSide(color: Color(0x22FFFFFF)),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Icon(
                          Icons.play_circle_fill_rounded,
                          color: Color(0xFF4FC3F7),
                          size: 34,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Red Cristiana TV',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return _TvSidebarItem(
                          item: item,
                          selected: _selectedIndex == index,
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 18),
                    child: Text(
                      'Streaming cristiano para pantalla grande',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Container(
                key: ValueKey(_selectedIndex),
                color: const Color(0xFF070B14),
                child: _screens[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TvMenuItem {
  final String label;
  final IconData icon;

  const _TvMenuItem({
    required this.label,
    required this.icon,
  });
}

class _TvSidebarItem extends StatelessWidget {
  final _TvMenuItem item;
  final bool selected;
  final VoidCallback onTap;

  const _TvSidebarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TvPressable(
        onPressed: onTap,
        builder: (context, focused) {
          final active = selected || focused;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: active ? const Color(0xFF1976FF) : Colors.transparent,
              border: Border.all(
                color: active
                    ? const Color(0x884FC3F7)
                    : const Color(0x16FFFFFF),
                width: active ? 1.6 : 1,
              ),
              boxShadow: active
                  ? [
                BoxShadow(
                  color: const Color(0xFF1976FF).withOpacity(0.30),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
              ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}