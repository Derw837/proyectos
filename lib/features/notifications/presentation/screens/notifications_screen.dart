import 'package:flutter/material.dart';
import 'package:red_cristiana/features/events/presentation/screens/event_detail_screen.dart';
import 'package:red_cristiana/features/notifications/data/notifications_service.dart';
import 'package:red_cristiana/features/notifications/presentation/screens/post_notification_detail_screen.dart';
import 'package:red_cristiana/features/notifications/presentation/screens/video_notification_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await NotificationsService.getMyNotifications();

      if (!mounted) return;
      setState(() {
        notifications = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando notificaciones: $e')),
      );
    }
  }

  Future<void> _openNotification(Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    final type = item['type']?.toString() ?? '';
    final relatedId = item['related_id']?.toString() ?? '';
    final isRead = item['is_read'] == true;

    if (!isRead && id.isNotEmpty) {
      await NotificationsService.markAsRead(id);
    }

    if (relatedId.isEmpty) {
      await _loadNotifications();
      return;
    }

    try {
      if (type == 'event') {
        final event = await NotificationsService.getEventById(relatedId);
        if (event == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El evento ya no está disponible')),
          );
        } else {
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(event: event),
            ),
          );
        }
      } else if (type == 'post') {
        final post = await NotificationsService.getPostById(relatedId);
        if (post == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('La publicación ya no está disponible')),
          );
        } else {
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostNotificationDetailScreen(post: post),
            ),
          );
        }
      }
      else if (type == 'video') {
        final video = await NotificationsService.getVideoById(relatedId);

        if (video == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El video no está disponible')),
          );
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoNotificationDetailScreen(video: video),
            ),
          );
        }
      }

      await _loadNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la notificación: $e')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    await NotificationsService.markAllAsRead();
    await _loadNotifications();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Todas las notificaciones se marcaron como leídas')),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'event':
        return Icons.event_outlined;
      case 'post':
        return Icons.photo_library_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'event':
        return Colors.deepOrange;
      case 'post':
        return const Color(0xFF0D47A1);
      default:
        return Colors.grey;
    }
  }

  Widget _notificationCard(Map<String, dynamic> item) {
    final title = item['title']?.toString() ?? '';
    final message = item['message']?.toString() ?? '';
    final type = item['type']?.toString() ?? '';
    final isRead = item['is_read'] == true;
    final createdAt = item['created_at']?.toString() ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openNotification(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFEAF4FF),
          borderRadius: BorderRadius.circular(20),
          border: !isRead
              ? Border.all(color: const Color(0xFF0D47A1), width: 1.2)
              : null,
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: _colorForType(type).withOpacity(0.12),
              child: Icon(
                _iconForType(type),
                color: _colorForType(type),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5,
                            color: isRead
                                ? Colors.black87
                                : const Color(0xFF0D1B2A),
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0D47A1),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                  if (createdAt.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      createdAt.split('T').first,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        notifications.where((item) => item['is_read'] != true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Notificaciones'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F9FC),
        actions: [
          if (!isLoading && notifications.isNotEmpty && unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Marcar todo'),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(
        child: Text(
          'No tienes notificaciones todavía.',
          textAlign: TextAlign.center,
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadNotifications,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) =>
              _notificationCard(notifications[index]),
        ),
      ),
    );
  }
}