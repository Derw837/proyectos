import 'package:flutter/material.dart';
import 'package:red_cristiana/core/utils/app_error_helper.dart';
import 'package:red_cristiana/features/churches/data/church_schedule_service.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/church_header_shell.dart';

class ChurchSchedulesManageScreen extends StatefulWidget {
  const ChurchSchedulesManageScreen({super.key});

  @override
  State<ChurchSchedulesManageScreen> createState() =>
      _ChurchSchedulesManageScreenState();
}

class _ChurchSchedulesManageScreenState
    extends State<ChurchSchedulesManageScreen> {
  static const Color _primary = Color(0xFF0D47A1);
  static const Color _primaryLight = Color(0xFF1565C0);
  static const Color _surface = Color(0xFFF4F7FB);
  static const Color _card = Colors.white;
  static const Color _textDark = Color(0xFF152033);
  static const Color _textSoft = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE6EDF6);

  bool isLoading = true;
  List<Map<String, dynamic>> schedules = [];

  final List<String> _daysOrder = const [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      final data = await ChurchScheduleService.getMySchedules();

      if (!mounted) return;
      setState(() {
        schedules = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(await AppErrorHelper.friendlyMessage(e, fallback: 'No se pudieron cargar los horarios en este momento.'))),
      );
    }
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

  List<Map<String, dynamic>> _sortedSchedules() {
    final copy = List<Map<String, dynamic>>.from(schedules);

    copy.sort((a, b) {
      final dayA = a['day_name']?.toString() ?? '';
      final dayB = b['day_name']?.toString() ?? '';

      final indexA = _daysOrder.indexOf(dayA);
      final indexB = _daysOrder.indexOf(dayB);

      if (indexA != indexB) {
        return indexA.compareTo(indexB);
      }

      final startA = a['start_time']?.toString() ?? '';
      final startB = b['start_time']?.toString() ?? '';
      return startA.compareTo(startB);
    });

    return copy;
  }

  Map<String, List<Map<String, dynamic>>> _groupedSchedules() {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final day in _daysOrder) {
      grouped[day] = [];
    }

    for (final item in _sortedSchedules()) {
      final day = item['day_name']?.toString() ?? '';
      if (!grouped.containsKey(day)) {
        grouped[day] = [];
      }
      grouped[day]!.add(item);
    }

    return grouped;
  }

  Future<void> _openCreateSheet() async {
    final serviceController = TextEditingController();
    final startController = TextEditingController();
    final endController = TextEditingController();

    final formKey = GlobalKey<FormState>();
    bool saving = false;
    String selectedDay = 'Domingo';

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                              children: const [
                                Text(
                                  'Nuevo horario',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Agrega cultos, reuniones, discipulados, vigilias o actividades semanales.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13.2,
                                    height: 1.35,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _TopChip(
                                      icon: Icons.schedule_outlined,
                                      text: 'Horario semanal',
                                    ),
                                    _TopChip(
                                      icon: Icons.access_time_outlined,
                                      text: 'Hora de inicio y fin',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Información del horario',
                            style: TextStyle(
                              color: _textDark,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: selectedDay,
                            decoration: decoration(
                              'Día',
                              Icons.calendar_today_outlined,
                            ),
                            items: _daysOrder.map((day) {
                              return DropdownMenuItem<String>(
                                value: day,
                                child: Text(day),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setSheetState(() {
                                selectedDay = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: serviceController,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Ingresa el nombre del servicio'
                                : null,
                            decoration: decoration(
                              'Nombre del servicio',
                              Icons.church_outlined,
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
                                  validator: (v) => v == null || v.trim().isEmpty
                                      ? 'Inicio'
                                      : null,
                                  decoration: decoration(
                                    'Hora inicio',
                                    Icons.access_time_outlined,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      onPressed: pickStartTime,
                                      icon: const Icon(
                                        Icons.schedule,
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
                                    Icons.more_time_outlined,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      onPressed: pickEndTime,
                                      icon: const Icon(
                                        Icons.schedule_outlined,
                                        color: _primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                                    style: TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: saving
                                      ? null
                                      : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }

                                    try {
                                      setSheetState(() {
                                        saving = true;
                                      });

                                      final church =
                                      await ChurchScheduleService
                                          .getMyChurch();

                                      if (church == null) {
                                        throw Exception(
                                          'No se encontró la iglesia',
                                        );
                                      }

                                      await ChurchScheduleService
                                          .createSchedule(
                                        churchId:
                                        church['id'].toString(),
                                        dayName: selectedDay,
                                        serviceName:
                                        serviceController.text.trim(),
                                        startTime: _normalizeHour(
                                          startController.text,
                                        ),
                                        endTime: _normalizeHour(
                                          endController.text,
                                        ),
                                      );

                                      if (!mounted) return;
                                      Navigator.pop(sheetContext, true);

                                    } catch (e) {
                                      if (!mounted) return;
                                      setSheetState(() {
                                        saving = false;
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            await AppErrorHelper.friendlyMessage(e, fallback: 'No se pudo guardar el horario en este momento.'),
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
                                      : const Icon(Icons.save_outlined),
                                  label: Text(
                                    saving ? 'Guardando...' : 'Guardar',
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
      await _loadSchedules();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Horario agregado correctamente'),
        ),
      );
    }

    serviceController.dispose();
    startController.dispose();
    endController.dispose();
  }

  Future<void> _deleteSchedule(String scheduleId) async {
    try {
      await ChurchScheduleService.deleteSchedule(scheduleId);
      await _loadSchedules();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horario eliminado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(await AppErrorHelper.friendlyMessage(e, fallback: 'No se pudo eliminar el horario en este momento.'))),
      );
    }
  }

  Future<void> _confirmDelete(String scheduleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Eliminar horario'),
          content: const Text(
            '¿Seguro que deseas eliminar este horario?',
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
      await _deleteSchedule(scheduleId);
    }
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
            'Horarios',
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
              _TopChip(
                icon: Icons.schedule_outlined,
                text: '${schedules.length} total',
              ),
              const _TopChip(
                icon: Icons.calendar_month_outlined,
                text: 'Semana organizada',
              ),
              const _TopChip(
                icon: Icons.access_time_outlined,
                text: 'Cultos y reuniones',
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
              Icons.view_week_outlined,
              color: _primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              schedules.isEmpty
                  ? 'Todavía no has agregado horarios.'
                  : (schedules.length == 1
                  ? 'Tienes 1 horario registrado.'
                  : 'Tienes ${schedules.length} horarios registrados.'),
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

  Widget _daySection(String day, List<Map<String, dynamic>> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: _primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  day,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: items.isEmpty
                      ? const Color(0xFFF4F7FB)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  items.isEmpty
                      ? 'Sin horarios'
                      : '${items.length} horario${items.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: items.isEmpty
                        ? _textSoft
                        : const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w800,
                    fontSize: 11.8,
                  ),
                ),
              ),
            ],
          ),
          if (items.isEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'No hay actividades registradas para este día.',
              style: TextStyle(
                color: _textSoft,
                fontSize: 13.1,
                height: 1.35,
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            ...items.map(_scheduleItemCard),
          ],
        ],
      ),
    );
  }

  Widget _scheduleItemCard(Map<String, dynamic> item) {
    final serviceName = item['service_name']?.toString().trim() ?? '';
    final startTime = item['start_time']?.toString().trim() ?? '';
    final endTime = item['end_time']?.toString().trim() ?? '';
    final scheduleId = item['id']?.toString() ?? '';

    String timeText = '';
    if (startTime.isNotEmpty && endTime.isNotEmpty) {
      timeText = '$startTime - $endTime';
    } else if (startTime.isNotEmpty) {
      timeText = startTime;
    } else if (endTime.isNotEmpty) {
      timeText = endTime;
    } else {
      timeText = 'Sin hora definida';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.access_time_outlined,
              color: _primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceName.isEmpty ? 'Servicio sin nombre' : serviceName,
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.2,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  timeText,
                  style: const TextStyle(
                    color: _textSoft,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: scheduleId.isEmpty ? null : () => _confirmDelete(scheduleId),
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 19,
                ),
              ),
            ),
          ),
        ],
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
              Icons.schedule_outlined,
              size: 38,
              color: _primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Todavía no has agregado horarios',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Agrega cultos, reuniones y actividades para que la comunidad vea el cronograma semanal de tu iglesia.',
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
                'Agregar primer horario',
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

  Widget _content() {
    final grouped = _groupedSchedules();

    return RefreshIndicator(
      onRefresh: _loadSchedules,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _heroCard(),
          const SizedBox(height: 18),
          _sectionTitle(
            'Resumen',
            'Organiza los horarios semanales de tu iglesia.',
          ),
          _summaryCard(),
          const SizedBox(height: 20),
          _sectionTitle(
            'Horarios por día',
            'Aquí aparecen las actividades registradas en la semana.',
          ),
          if (schedules.isEmpty)
            _emptyState()
          else
            ..._daysOrder.map(
                  (day) => _daySection(day, grouped[day] ?? []),
            ),
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
            'Nuevo horario',
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

class _TopChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TopChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
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
}