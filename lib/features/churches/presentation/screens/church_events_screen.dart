import 'package:flutter/material.dart';
import 'package:red_cristiana/features/events/data/church_events_service.dart';

class ChurchEventsScreen extends StatefulWidget {
  final String churchId;
  final String churchName;

  const ChurchEventsScreen({
    super.key,
    required this.churchId,
    required this.churchName,
  });

  @override
  State<ChurchEventsScreen> createState() => _ChurchEventsScreenState();
}

class _ChurchEventsScreenState extends State<ChurchEventsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final data = await ChurchEventsService.getChurchEvents(widget.churchId);

      if (!mounted) return;
      setState(() {
        events = data;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _eventCard(Map<String, dynamic> event) {
    final title = event['title']?.toString() ?? '';
    final description = event['description']?.toString() ?? '';
    final date = event['event_date']?.toString() ?? '';
    final start = event['start_time']?.toString() ?? '';
    final end = event['end_time']?.toString() ?? '';
    final address = event['address']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
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
            Text('Fecha: $date'),
          ],
          if (start.isNotEmpty || end.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Hora: $start${end.isNotEmpty ? ' - $end' : ''}',
              style: const TextStyle(
                color: Color(0xFF0D47A1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (address.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Lugar: $address'),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text('Eventos de ${widget.churchName}'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : events.isEmpty
          ? const Center(
        child: Text('No hay eventos disponibles.'),
      )
          : RefreshIndicator(
        onRefresh: _loadEvents,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) => _eventCard(events[index]),
        ),
      ),
    );
  }
}