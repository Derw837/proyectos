import 'dart:async';
import 'package:flutter/material.dart';
import 'package:red_cristiana/navigator_key.dart';

class InAppNotificationBanner {
  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  static void show({
    required String title,
    required String body,
  }) {
    _timer?.cancel();
    _removeCurrent();

    final overlay = appNavigatorKey.currentState?.overlay;
    if (overlay == null) {
      debugPrint('No se encontró overlay para mostrar banner');
      return;
    }

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return _AnimatedTopBanner(
          title: title,
          body: body,
          onClose: () {
            _removeCurrent();
          },
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _timer = Timer(const Duration(seconds: 5), () async {
      await _removeCurrentAnimated();
    });
  }

  static Future<void> _removeCurrentAnimated() async {
    _timer?.cancel();
    _timer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static void _removeCurrent() {
    _timer?.cancel();
    _timer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _AnimatedTopBanner extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onClose;

  const _AnimatedTopBanner({
    required this.title,
    required this.body,
    required this.onClose,
  });

  @override
  State<_AnimatedTopBanner> createState() => _AnimatedTopBannerState();
}

class _AnimatedTopBannerState extends State<_AnimatedTopBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  bool _closing = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 260),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _controller.forward();
  }

  Future<void> _dismiss() async {
    if (_closing) return;
    _closing = true;
    await _controller.reverse();
    widget.onClose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 12,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: SlideTransition(
            position: _offsetAnimation,
            child: Container(
              margin: EdgeInsets.only(top: topPadding > 0 ? 4 : 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0D47A1),
                    Color(0xFF1565C0),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: _dismiss,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.notifications_active_outlined,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _dismiss,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}