import 'package:flutter/material.dart';

class MainHeader extends StatelessWidget {
  final VoidCallback? onNotifications;
  final VoidCallback? onDonate;
  final VoidCallback? onStore;
  final VoidCallback? onProfile;
  final int notificationCount;

  const MainHeader({
    super.key,
    this.onNotifications,
    this.onDonate,
    this.onStore,
    this.onProfile,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 8;

    return Container(
      padding: EdgeInsets.fromLTRB(14, topPadding, 14, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFFF4F7FD),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Image.asset(
                      'assets/images/logo_header.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Red Cristiana',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0D1B2A),
                        ),
                      ),
                      SizedBox(height: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: onNotifications,
                icon: const Icon(Icons.notifications_outlined),
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      notificationCount > 9 ? '9+' : '$notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          _HeaderIconWithLabel(
            icon: Icons.favorite_outline,
            label: 'Apóyanos',
            onTap: onDonate,
          ),
          const SizedBox(width: 4),
          _HeaderIconWithLabel(
            icon: Icons.storefront_outlined,
            label: 'Tienda',
            onTap: onStore,
          ),
          const SizedBox(width: 4),
          _HeaderIconWithLabel(
            icon: Icons.person_outline,
            label: 'Perfil',
            onTap: onProfile,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconWithLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _HeaderIconWithLabel({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 55,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
