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

  String selectedPeriod = 'week';
  String selectedType = 'all';

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

      _showMessage('Error cargando notificaciones: $e');
    }
  }

  Future<void> _openNotification(Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    final type = item['type']?.toString() ?? '';
    final relatedId = item['related_id']?.toString() ?? '';
    final isRead = item['is_read'] == true;
    final duplicateIds =
    List<String>.from(item['duplicate_ids'] ?? <String>[]);

    try {
      if (!isRead) {
        if (duplicateIds.isNotEmpty) {
          await NotificationsService.markManyAsRead(duplicateIds);
        } else if (id.isNotEmpty) {
          await NotificationsService.markAsRead(id);
        }
      }

      if (relatedId.isEmpty && type != 'prayer_request') {
        await _loadNotifications();
        return;
      }

      if (type == 'event') {
        final event = await NotificationsService.getEventById(relatedId);

        if (!mounted) return;

        if (event == null) {
          _showMessage('El evento ya no está disponible');
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(event: event),
            ),
          );
        }
      } else if (type == 'post') {
        final post = await NotificationsService.getPostById(relatedId);

        if (!mounted) return;

        if (post == null) {
          _showMessage('La publicación ya no está disponible');
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostNotificationDetailScreen(post: post),
            ),
          );
        }
      } else if (type == 'video') {
        final video = await NotificationsService.getVideoById(relatedId);

        if (!mounted) return;

        if (video == null) {
          _showMessage('El video no está disponible');
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoNotificationDetailScreen(video: video),
            ),
          );
        }
      } else if (type == 'prayer_request') {
        if (!mounted) return;
        _showMessage('La petición de oración fue marcada como leída');
      } else {
        if (!mounted) return;
        _showMessage('Tipo de notificación no soportado');
      }

      await _loadNotifications();
    } catch (e) {
      if (!mounted) return;
      _showMessage('No se pudo abrir la notificación: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationsService.markAllAsRead();
      await _loadNotifications();

      if (!mounted) return;
      _showMessage('Todas las notificaciones se marcaron como leídas');
    } catch (e) {
      if (!mounted) return;
      _showMessage('No se pudieron marcar como leídas: $e');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'event':
        return Icons.event_outlined;
      case 'post':
        return Icons.article_outlined;
      case 'video':
        return Icons.play_circle_outline_rounded;
      case 'prayer_request':
        return Icons.volunteer_activism_outlined;
      case 'church_announcement':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'event':
        return const Color(0xFFE67E22);
      case 'post':
        return const Color(0xFF1565C0);
      case 'video':
        return const Color(0xFF8E24AA);
      case 'prayer_request':
        return const Color(0xFF2E7D32);
      case 'church_announcement':
        return const Color(0xFF6A1B9A);
      default:
        return const Color(0xFF78909C);
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'event':
        return 'Evento';
      case 'post':
        return 'Post';
      case 'video':
        return 'Video';
      case 'prayer_request':
        return 'Oración';
      case 'church_announcement':
        return 'Anuncio';
      default:
        return 'General';
    }
  }

  String _formatDate(String value) {
    if (value.isEmpty) return '';

    try {
      final date = DateTime.parse(value).toLocal();

      const months = [
        'ene',
        'feb',
        'mar',
        'abr',
        'may',
        'jun',
        'jul',
        'ago',
        'sep',
        'oct',
        'nov',
        'dic',
      ];

      final day = date.day.toString().padLeft(2, '0');
      final month = months[date.month - 1];
      final year = date.year;
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';

      return '$day $month $year • $hour:$minute $period';
    } catch (_) {
      return value.split('T').first;
    }
  }

  String _sectionTitleForDate(String value) {
    try {
      final date = DateTime.parse(value).toLocal();
      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);
      final itemDay = DateTime(date.year, date.month, date.day);

      final difference = today.difference(itemDay).inDays;

      if (difference <= 0) {
        return 'Hoy';
      }

      if (difference <= 7) {
        return 'Esta semana';
      }

      return 'Anteriores';
    } catch (_) {
      return 'Anteriores';
    }
  }

  bool _matchesPeriod(String createdAt) {
    if (createdAt.isEmpty) return false;

    try {
      final date = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();

      final notificationDate = DateTime(date.year, date.month, date.day);
      final today = DateTime(now.year, now.month, now.day);

      final difference = today.difference(notificationDate).inDays;

      if (selectedPeriod == 'day') {
        return difference == 0;
      }

      if (selectedPeriod == 'week') {
        return difference >= 0 && difference <= 7;
      }

      if (selectedPeriod == 'month') {
        return date.year == now.year && date.month == now.month;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  List<Map<String, dynamic>> _filteredNotifications() {
    return notifications.where((item) {
      final createdAt = item['created_at']?.toString() ?? '';
      final type = item['type']?.toString() ?? '';

      final matchesType = selectedType == 'all' || type == selectedType;
      final matchesPeriod = _matchesPeriod(createdAt);

      return matchesType && matchesPeriod;
    }).toList();
  }

  Widget _buildHeader(int unreadCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D47A1),
            Color(0xFF1565C0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180D47A1),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tus notificaciones',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  unreadCount > 0
                      ? '$unreadCount sin leer'
                      : 'Todo al día',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Color(0xFF0D47A1),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          _buildMiniPeriodButton('Día', 'day'),
          const SizedBox(width: 6),
          _buildMiniPeriodButton('Semana', 'week'),
          const SizedBox(width: 6),
          _buildMiniPeriodButton('Mes', 'month'),
        ],
      ),
    );
  }

  Widget _buildMiniPeriodButton(String label, String value) {
    final isSelected = selectedPeriod == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPeriod = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0D47A1)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.2,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilters() {
    return SizedBox(
      height: 40,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        scrollDirection: Axis.horizontal,
        children: [
          _buildMiniTypeChip('Todas', 'all'),
          _buildMiniTypeChip('Eventos', 'event'),
          _buildMiniTypeChip('Posts', 'post'),
          _buildMiniTypeChip('Videos', 'video'),
          _buildMiniTypeChip('Oración', 'prayer_request'),
          _buildMiniTypeChip('Anuncios', 'church_announcement'),
        ],
      ),
    );
  }

  Widget _buildMiniTypeChip(String label, String value) {
    final isSelected = selectedType == value;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedType = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFDBEAFE) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1565C0)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.2,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF1565C0)
                  : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnreadButton(int unreadCount) {
    if (isLoading || notifications.isEmpty || unreadCount <= 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: _markAllAsRead,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF0D47A1),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(
                color: Color(0x220D47A1),
              ),
            ),
          ),
          icon: const Icon(Icons.done_all_rounded, size: 16),
          label: const Text(
            'Marcar todas',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: title == 'Hoy'
                  ? const Color(0xFF0D47A1)
                  : const Color(0xFF102A43),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Divider(
              thickness: 1,
              color: Color(0xFFE5EAF1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationCard(Map<String, dynamic> item) {
    final title = item['title']?.toString() ?? '';
    final message = item['message']?.toString() ?? '';
    final type = item['type']?.toString() ?? '';
    final isRead = item['is_read'] == true;
    final createdAt = item['created_at']?.toString() ?? '';
    final groupedCount = (item['grouped_count'] as int?) ?? 1;

    final typeColor = _colorForType(type);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openNotification(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 2, right: 2),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF2F8FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRead ? const Color(0xFFE7ECF3) : const Color(0xFFBFDBFE),
            width: 1.1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                _iconForType(type),
                color: typeColor,
                size: 22,
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
                          title.isEmpty ? 'Sin título' : title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: isRead
                                ? const Color(0xFF1F2937)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1565C0),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _labelForType(type),
                          style: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 10.8,
                          ),
                        ),
                      ),
                      if (groupedCount > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'x$groupedCount',
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      if (createdAt.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _formatDate(createdAt),
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.isEmpty ? 'Sin descripción' : message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      height: 1.4,
                      fontSize: 13,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        groupedCount > 1 ? 'Abrir grupo' : 'Abrir',
                        style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: Color(0xFF1565C0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 36,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin notificaciones',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        notifications.where((item) => item['is_read'] != true).length;

    final filteredNotifications = _filteredNotifications();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF5F7FB),
        centerTitle: true,
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(unreadCount),
          _buildPeriodSelector(),
          _buildTypeFilters(),
          _buildUnreadButton(unreadCount),
          Expanded(
            child: isLoading
                ? _buildLoadingState()
                : notifications.isEmpty
                ? _buildEmptyState(
              'Cuando haya nuevas publicaciones, eventos o avisos, aparecerán aquí.',
            )
                : filteredNotifications.isEmpty
                ? _buildEmptyState(
              'No hay notificaciones para este filtro seleccionado.',
            )
                : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                itemCount: filteredNotifications.length,
                itemBuilder: (context, index) {
                  final item = filteredNotifications[index];
                  final createdAt = item['created_at']?.toString() ?? '';
                  final currentSection = _sectionTitleForDate(createdAt);

                  String? previousSection;
                  if (index > 0) {
                    final previousCreatedAt =
                        filteredNotifications[index - 1]['created_at']
                            ?.toString() ??
                            '';
                    previousSection = _sectionTitleForDate(previousCreatedAt);
                  }

                  final showHeader =
                      index == 0 || currentSection != previousSection;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showHeader) _sectionHeader(currentSection),
                      _notificationCard(item),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}