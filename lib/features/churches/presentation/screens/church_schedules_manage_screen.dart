import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/data/church_schedule_service.dart';

class ChurchSchedulesManageScreen extends StatefulWidget {
  const ChurchSchedulesManageScreen({super.key});

  @override
  State<ChurchSchedulesManageScreen> createState() =>
      _ChurchSchedulesManageScreenState();
}

class _ChurchSchedulesManageScreenState
    extends State<ChurchSchedulesManageScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> schedules = [];

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
        schedules = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando horarios: $e')),
      );
    }
  }

  Future<void> _openDialog({Map<String, dynamic>? current}) async {
    final isEditing = current != null;

    final dayController =
    TextEditingController(text: current?['day_name']?.toString() ?? '');
    final serviceController =
    TextEditingController(text: current?['service_name']?.toString() ?? '');
    final startController =
    TextEditingController(text: current?['start_time']?.toString() ?? '');
    final endController =
    TextEditingController(text: current?['end_time']?.toString() ?? '');

    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            InputDecoration decoration(String label, IconData icon) {
              return InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              );
            }

            return AlertDialog(
              title: Text(isEditing ? 'Editar horario' : 'Nuevo horario'),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: dayController,
                          validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Ingresa el día' : null,
                          decoration: decoration('Día', Icons.calendar_today_outlined),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: serviceController,
                          decoration: decoration(
                            'Nombre del servicio',
                            Icons.church_outlined,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: startController,
                          decoration:
                          decoration('Hora inicio', Icons.access_time),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: endController,
                          decoration:
                          decoration('Hora fin', Icons.timelapse),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                if (isEditing)
                  TextButton(
                    onPressed: saving
                        ? null
                        : () async {
                      try {
                        setDialogState(() {
                          saving = true;
                        });

                        await ChurchScheduleService.deleteSchedule(
                          current['id'].toString(),
                        );

                        if (!mounted) return;
                        Navigator.pop(dialogContext);
                        await _loadSchedules();

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Horario eliminado correctamente'),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        setDialogState(() {
                          saving = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error eliminando: $e')),
                        );
                      }
                    },
                    child: const Text('Eliminar'),
                  ),
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                    if (!formKey.currentState!.validate()) return;

                    try {
                      setDialogState(() {
                        saving = true;
                      });

                      if (isEditing) {
                        await ChurchScheduleService.updateSchedule(
                          scheduleId: current['id'].toString(),
                          dayName: dayController.text.trim(),
                          serviceName: serviceController.text.trim(),
                          startTime: startController.text.trim(),
                          endTime: endController.text.trim(),
                        );
                      } else {
                        final church =
                        await ChurchScheduleService.getMyChurch();
                        if (church == null) {
                          throw Exception(
                            'No se encontró la iglesia del usuario',
                          );
                        }

                        await ChurchScheduleService.createSchedule(
                          churchId: church['id'].toString(),
                          dayName: dayController.text.trim(),
                          serviceName: serviceController.text.trim(),
                          startTime: startController.text.trim(),
                          endTime: endController.text.trim(),
                        );
                      }

                      if (!mounted) return;
                      Navigator.pop(dialogContext);
                      await _loadSchedules();

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? 'Horario actualizado correctamente'
                                : 'Horario creado correctamente',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      setDialogState(() {
                        saving = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error guardando: $e')),
                      );
                    }
                  },
                  child: saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(isEditing ? 'Guardar' : 'Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _scheduleCard(Map<String, dynamic> item) {
    final day = item['day_name']?.toString() ?? '';
    final service = item['service_name']?.toString() ?? '';
    final start = item['start_time']?.toString() ?? '';
    final end = item['end_time']?.toString() ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _openDialog(current: item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFEAF4FF),
              child: Icon(Icons.schedule, color: Color(0xFF0D47A1)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (service.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      service,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                  if (start.isNotEmpty || end.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$start${end.isNotEmpty ? " - $end" : ""}',
                      style: const TextStyle(
                        color: Color(0xFF0D47A1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Horarios de mi iglesia'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openDialog(),
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : schedules.isEmpty
          ? const Center(
        child: Text('Aún no has agregado horarios.'),
      )
          : RefreshIndicator(
        onRefresh: _loadSchedules,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: schedules.length,
          itemBuilder: (context, index) =>
              _scheduleCard(schedules[index]),
        ),
      ),
    );
  }
}