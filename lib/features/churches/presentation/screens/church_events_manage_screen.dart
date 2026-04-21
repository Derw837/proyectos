import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:red_cristiana/core/utils/app_error_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/church_header_shell.dart';
import 'package:red_cristiana/features/events/data/church_events_service.dart';

class ChurchEventsManageScreen extends StatefulWidget {
  const ChurchEventsManageScreen({super.key});

  @override
  State<ChurchEventsManageScreen> createState() =>
      _ChurchEventsManageScreenState();
}

class _ChurchEventsManageScreenState extends State<ChurchEventsManageScreen> {
  static const Color _primary = Color(0xFF0D47A1);
  static const Color _primaryLight = Color(0xFF1565C0);
  static const Color _surface = Color(0xFFF4F7FB);
  static const Color _card = Colors.white;
  static const Color _textDark = Color(0xFF152033);
  static const Color _textSoft = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE6EDF6);

  bool isLoading = true;
  List<Map<String, dynamic>> events = [];
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final data = await ChurchEventsService.getMyEvents();

      if (!mounted) return;
      setState(() {
        events = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(await AppErrorHelper.friendlyMessage(e, fallback: 'No se pudieron cargar los eventos en este momento.'))),
      );
    }
  }

  String _formatDateForDisplay(String date) {
    if (date.trim().isEmpty) return 'Sin fecha';

    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;

    const months = [
      '',
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
      'dic'
    ];

    return '${parsed.day} ${months[parsed.month]} ${parsed.year}';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _normalizeHour(String value) {
    final text = value.trim();
    if (text.isEmpty) return '';
    return text;
  }

  Future<void> _openCreateSheet() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final dateController = TextEditingController();
    final startController = TextEditingController();
    final endController = TextEditingController();
    final addressController = TextEditingController();

    XFile? pickedImage;
    Uint8List? imageBytes;

    bool saving = false;
    final formKey = GlobalKey<FormState>();

    final church = await ChurchEventsService.getMyChurch();
    if (!mounted || church == null) return;

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickImage() async {
              final picked = await picker.pickImage(source: ImageSource.gallery);
              if (picked == null) return;

              final bytes = await picked.readAsBytes();

              setSheetState(() {
                pickedImage = picked;
                imageBytes = bytes;
              });
            }

            Future<void> pickDate() async {
              final now = DateTime.now();
              final selected = await showDatePicker(
                context: context,
                initialDate: now,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 5),
              );

              if (selected == null) return;

              final yyyy = selected.year.toString().padLeft(4, '0');
              final mm = selected.month.toString().padLeft(2, '0');
              final dd = selected.day.toString().padLeft(2, '0');

              setSheetState(() {
                dateController.text = '$yyyy-$mm-$dd';
              });
            }

            Future<void> pickStartTime() async {
              final selected = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 19, minute: 0),
              );

              if (selected == null) return;

              setSheetState(() {
                startController.text = _formatTimeOfDay(selected);
              });
            }

            Future<void> pickEndTime() async {
              final selected = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 21, minute: 0),
              );

              if (selected == null) return;

              setSheetState(() {
                endController.text = _formatTimeOfDay(selected);
              });
            }

            InputDecoration decoration(String label, IconData icon) {
              return InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                  color: _textSoft,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: Icon(icon, color: _primary, size: 21),
                filled: true,
                fillColor: const Color(0xFFF9FBFE),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: _primary, width: 1.3),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Colors.red, width: 1.2),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: _border),
                ),
              );
            }

            return Container(
              decoration: const BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                  ),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 52,
                              height: 5,
                              decoration: BoxDecoration(
                                color: const Color(0xFFCAD5E5),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_primary, _primaryLight],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Nuevo evento',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Crea actividades, campañas, conferencias o reuniones especiales.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13.2,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _topChip(
                                      icon: Icons.event_available_outlined,
                                      text: 'Publicación rápida',
                                    ),
                                    _topChip(
                                      icon: Icons.image_outlined,
                                      text: 'Imagen opcional',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Información principal',
                            style: TextStyle(
                              color: _textDark,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: titleController,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Ingresa el título'
                                : null,
                            decoration:
                            decoration('Título del evento', Icons.title),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: descriptionController,
                            maxLines: 4,
                            decoration: decoration(
                              'Descripción',
                              Icons.description_outlined,
                            ).copyWith(
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Fecha y horario',
                            style: TextStyle(
                              color: _textDark,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: dateController,
                            readOnly: true,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Selecciona la fecha'
                                : null,
                            onTap: pickDate,
                            decoration: decoration(
                              'Fecha del evento',
                              Icons.date_range_outlined,
                            ).copyWith(
                              suffixIcon: IconButton(
                                onPressed: pickDate,
                                icon: const Icon(
                                  Icons.calendar_month_outlined,
                                  color: _primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: startController,
                                  readOnly: true,
                                  onTap: pickStartTime,
                                  decoration: decoration(
                                    'Hora inicio',
                                    Icons.schedule_outlined,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      onPressed: pickStartTime,
                                      icon: const Icon(
                                        Icons.access_time_outlined,
                                        color: _primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: endController,
                                  readOnly: true,
                                  onTap: pickEndTime,
                                  decoration: decoration(
                                    'Hora fin',
                                    Icons.schedule,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      onPressed: pickEndTime,
                                      icon: const Icon(
                                        Icons.access_time_filled_outlined,
                                        color: _primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Ubicación',
                            style: TextStyle(
                              color: _textDark,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: addressController,
                            decoration: decoration(
                              'Dirección del evento',
                              Icons.location_on_outlined,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Imagen promocional',
                            style: TextStyle(
                              color: _textDark,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: pickImage,
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              width: double.infinity,
                              height: 190,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: _border),
                              ),
                              child: imageBytes != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.memory(
                                      imageBytes!,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      right: 12,
                                      top: 12,
                                      child: Container(
                                        padding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.36),
                                          borderRadius:
                                          BorderRadius.circular(999),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.edit_outlined,
                                              color: Colors.white,
                                              size: 15,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Cambiar',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight:
                                                FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  : Column(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 42,
                                    color: _primary,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Seleccionar imagen promocional',
                                    style: TextStyle(
                                      color: _textDark,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Opcional',
                                    style: TextStyle(
                                      color: _textSoft,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: saving
                                      ? null
                                      : () => Navigator.pop(sheetContext),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _primary,
                                    side: const BorderSide(color: _border),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancelar',
                                    style:
                                    TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: saving
                                      ? null
                                      : () async {
                                    if (!formKey.currentState!
                                        .validate()) {
                                      return;
                                    }

                                    try {
                                      setSheetState(() => saving = true);

                                      String? imageUrl;
                                      if (pickedImage != null &&
                                          imageBytes != null) {
                                        imageUrl =
                                        await ChurchEventsService
                                            .uploadEventImage(
                                          churchId:
                                          church['id'].toString(),
                                          filePath: pickedImage!.path,
                                          bytes: imageBytes!,
                                        );
                                      }

                                      await ChurchEventsService
                                          .createEvent(
                                        churchId:
                                        church['id'].toString(),
                                        title:
                                        titleController.text.trim(),
                                        description: descriptionController
                                            .text
                                            .trim(),
                                        eventDate:
                                        dateController.text.trim(),
                                        startTime: _normalizeHour(
                                          startController.text,
                                        ),
                                        endTime: _normalizeHour(
                                          endController.text,
                                        ),
                                        country: church['country']
                                            ?.toString() ??
                                            '',
                                        city: church['city']
                                            ?.toString() ??
                                            '',
                                        sector: church['sector']
                                            ?.toString() ??
                                            '',
                                        address:
                                        addressController.text.trim(),
                                        imageUrl: imageUrl,
                                      );

                                      if (!mounted) return;
                                      Navigator.pop(sheetContext, true);

                                    } catch (e) {
                                      if (!mounted) return;
                                      setSheetState(() => saving = false);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            await AppErrorHelper.friendlyMessage(e, fallback: 'No se pudo crear el evento en este momento.'),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: saving
                                      ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.1,
                                      color: Colors.white,
                                    ),
                                  )
                                      : const Icon(Icons.publish_outlined),
                                  label: Text(
                                    saving ? 'Guardando...' : 'Publicar',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primary,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                    const Color(0xFFB8C7E0),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (created == true) {
      await _loadEvents();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento creado correctamente'),
        ),
      );
    }

    titleController.dispose();
    descriptionController.dispose();
    dateController.dispose();
    startController.dispose();
    endController.dispose();
    addressController.dispose();
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      await ChurchEventsService.deleteEvent(eventId);
      await _loadEvents();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento eliminado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(await AppErrorHelper.friendlyMessage(e, fallback: 'No se pudo eliminar el evento en este momento.'))),
      );
    }
  }

  Future<void> _confirmDelete(String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Eliminar evento'),
          content: const Text(
            '¿Seguro que deseas eliminar este evento?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteEvent(eventId);
    }
  }

  Widget _topChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: _textSoft,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220D47A1),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Eventos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _topChip(
                icon: Icons.event_available_outlined,
                text: '${events.length} total',
              ),
              _topChip(
                icon: Icons.campaign_outlined,
                text: 'Actividades',
              ),
              _topChip(
                icon: Icons.auto_awesome_outlined,
                text: 'Gestión pastoral',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: _primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              events.isEmpty
                  ? 'Todavía no hay eventos publicados.'
                  : (events.length == 1
                  ? 'Tienes 1 evento publicado.'
                  : 'Tienes ${events.length} eventos publicados.'),
              style: const TextStyle(
                color: _textDark,
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagChip({
    required IconData icon,
    required String text,
    Color bgColor = const Color(0xFFEAF2FF),
    Color textColor = _primary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 11.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(Map<String, dynamic> event) {
    final title = event['title']?.toString().trim() ?? '';
    final description = event['description']?.toString().trim() ?? '';
    final date = event['event_date']?.toString().trim() ?? '';
    final start = event['start_time']?.toString().trim() ?? '';
    final end = event['end_time']?.toString().trim() ?? '';
    final address = event['address']?.toString().trim() ?? '';
    final imageUrl = event['image_url']?.toString().trim() ?? '';
    final eventId = event['id']?.toString() ?? '';

    final hasSchedule = start.isNotEmpty || end.isNotEmpty;
    final hasAddress = address.isNotEmpty;

    String scheduleText = '';
    if (start.isNotEmpty && end.isNotEmpty) {
      scheduleText = '$start - $end';
    } else if (start.isNotEmpty) {
      scheduleText = start;
    } else if (end.isNotEmpty) {
      scheduleText = end;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 190,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return _eventPlaceholder();
                  },
                )
                    : _eventPlaceholder(),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: eventId.isEmpty ? null : () => _confirmDelete(eventId),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Evento sin título' : title,
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (date.isNotEmpty)
                      _tagChip(
                        icon: Icons.calendar_today_outlined,
                        text: _formatDateForDisplay(date),
                      ),
                    if (hasSchedule)
                      _tagChip(
                        icon: Icons.access_time_outlined,
                        text: scheduleText,
                        bgColor: const Color(0xFFE8F5E9),
                        textColor: const Color(0xFF2E7D32),
                      ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                      color: _textSoft,
                      fontSize: 13.2,
                      height: 1.45,
                    ),
                  ),
                ],
                if (hasAddress) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: _textSoft,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(
                            color: _textSoft,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventPlaceholder() {
    return Container(
      color: const Color(0xFFEAF2FF),
      child: const Center(
        child: Icon(
          Icons.event_available_outlined,
          color: _primary,
          size: 46,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.event_busy_outlined,
              size: 38,
              color: _primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Todavía no has publicado eventos',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Crea campañas, reuniones, conciertos o actividades especiales para que tu comunidad pueda verlas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSoft,
              fontSize: 13.2,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _openCreateSheet,
              icon: const Icon(Icons.add),
              label: const Text(
                'Crear primer evento',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _heroCard(),
          const SizedBox(height: 18),
          _sectionTitle(
            'Resumen',
            'Organiza las actividades y publicaciones de tu iglesia.',
          ),
          _summaryCard(),
          const SizedBox(height: 20),
          _sectionTitle(
            'Listado de eventos',
            'Aquí aparecen todos los eventos publicados.',
          ),
          if (events.isEmpty) _emptyState() else ...events.map(_eventCard),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChurchHeaderShell(
      child: Scaffold(
        backgroundColor: _surface,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreateSheet,
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.add),
          label: const Text(
            'Nuevo evento',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _content(),
      ),
    );
  }
}