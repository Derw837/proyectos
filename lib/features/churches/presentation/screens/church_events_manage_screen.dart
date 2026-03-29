import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:red_cristiana/features/events/data/church_events_service.dart';

class ChurchEventsManageScreen extends StatefulWidget {
  const ChurchEventsManageScreen({super.key});

  @override
  State<ChurchEventsManageScreen> createState() =>
      _ChurchEventsManageScreenState();
}

class _ChurchEventsManageScreenState extends State<ChurchEventsManageScreen> {
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
        SnackBar(content: Text('Error cargando eventos: $e')),
      );
    }
  }

  Future<void> _openCreateDialog() async {
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
    if (church == null) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImage() async {
              final picked = await picker.pickImage(source: ImageSource.gallery);
              if (picked == null) return;

              final bytes = await picked.readAsBytes();

              setDialogState(() {
                pickedImage = picked;
                imageBytes = bytes;
              });
            }

            return AlertDialog(
              title: const Text('Nuevo evento'),
              content: SizedBox(
                width: 440,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: titleController,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Ingresa el título'
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Título',
                            prefixIcon: const Icon(Icons.title),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Descripción',
                            prefixIcon: const Icon(Icons.description_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: dateController,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Ingresa la fecha YYYY-MM-DD'
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Fecha (YYYY-MM-DD)',
                            prefixIcon: const Icon(Icons.date_range),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: startController,
                                decoration: InputDecoration(
                                  labelText: 'Hora inicio',
                                  prefixIcon: const Icon(Icons.schedule),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: endController,
                                decoration: InputDecoration(
                                  labelText: 'Hora fin',
                                  prefixIcon:
                                  const Icon(Icons.schedule_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: addressController,
                          decoration: InputDecoration(
                            labelText: 'Dirección',
                            prefixIcon:
                            const Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        InkWell(
                          onTap: pickImage,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: double.infinity,
                            height: 170,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: imageBytes != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.memory(
                                imageBytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                                : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    size: 38),
                                SizedBox(height: 10),
                                Text('Seleccionar imagen promocional'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
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
                      setDialogState(() => saving = true);

                      String? imageUrl;
                      if (pickedImage != null && imageBytes != null) {
                        imageUrl =
                        await ChurchEventsService.uploadEventImage(
                          churchId: church['id'].toString(),
                          filePath: pickedImage!.path,
                          bytes: imageBytes!,
                        );
                      }

                      await ChurchEventsService.createEvent(
                        churchId: church['id'].toString(),
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        eventDate: dateController.text.trim(),
                        startTime: startController.text.trim(),
                        endTime: endController.text.trim(),
                        country: church['country']?.toString() ?? '',
                        city: church['city']?.toString() ?? '',
                        sector: church['sector']?.toString() ?? '',
                        address: addressController.text.trim(),
                        imageUrl: imageUrl,
                      );

                      if (!mounted) return;
                      Navigator.pop(dialogContext);
                      await _loadEvents();

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Evento creado correctamente')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      setDialogState(() => saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Error creando evento: $e')),
                      );
                    }
                  },
                  child: saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Publicar'),
                ),
              ],
            );
          },
        );
      },
    );
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
        SnackBar(content: Text('Error eliminando evento: $e')),
      );
    }
  }

  Widget _eventCard(Map<String, dynamic> event) {
    final title = event['title']?.toString() ?? '';
    final description = event['description']?.toString() ?? '';
    final date = event['event_date']?.toString() ?? '';
    final imageUrl = event['image_url']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              width: double.infinity,
              height: 190,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    date,
                    style: const TextStyle(
                      color: Color(0xFF0D47A1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Eventos de mi iglesia'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : events.isEmpty
          ? const Center(child: Text('No hay eventos todavía.'))
          : RefreshIndicator(
        onRefresh: _loadEvents,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Stack(
              children: [
                _eventCard(event),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton.filled(
                    onPressed: () =>
                        _deleteEvent(event['id'].toString()),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}