import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/data/models/church_model.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_detail_screen.dart';
import 'package:red_cristiana/features/events/presentation/screens/event_image_viewer_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailScreen extends StatelessWidget {
  final Map<String, dynamic> event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  Future<void> _openUrl(BuildContext context, String url) async {
    if (url.trim().isEmpty) return;
    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace')),
      );
    }
  }

  Future<void> _callPhone(BuildContext context, String phone) async {
    await _openUrl(context, 'tel:$phone');
  }

  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    final cleaned = phone.replaceAll(' ', '');
    await _openUrl(context, 'https://wa.me/$cleaned');
  }

  @override
  Widget build(BuildContext context) {
    final title = event['title']?.toString() ?? '';
    final description = event['description']?.toString() ?? '';
    final date = event['event_date']?.toString() ?? '';
    final start = event['start_time']?.toString() ?? '';
    final end = event['end_time']?.toString() ?? '';
    final country = event['country']?.toString() ?? '';
    final city = event['city']?.toString() ?? '';
    final sector = event['sector']?.toString() ?? '';
    final address = event['address']?.toString() ?? '';
    final imageUrl = event['image_url']?.toString() ?? '';

    final churchData = event['churches'];
    ChurchModel? church;

    if (churchData is Map<String, dynamic>) {
      church = ChurchModel.fromMap(churchData);
    }

    final location = [
      if (city.isNotEmpty) city,
      if (country.isNotEmpty) country,
    ].join(', ');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Detalle del evento'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventImageViewerScreen(imageUrl: imageUrl),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 230,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF7043),
                    Color(0xFFF4511E),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Evento',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      date,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (church != null)
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChurchDetailScreen(church: church!),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFEAF4FF),
                        backgroundImage: church.logoUrl != null &&
                            church.logoUrl!.isNotEmpty
                            ? NetworkImage(church.logoUrl!)
                            : null,
                        child: church.logoUrl == null || church.logoUrl!.isEmpty
                            ? const Icon(
                          Icons.church,
                          color: Color(0xFF0D47A1),
                        )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          church.churchName,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 18),
            _infoCard('Fecha', date),
            _infoCard('Hora', '$start${end.isNotEmpty ? ' - $end' : ''}'),
            _infoCard('Ubicación', location),
            _infoCard('Sector', sector),
            _infoCard('Dirección', address),
            _infoCard('Descripción', description),
            if (church != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (church.phone.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _callPhone(context, church!.phone),
                          icon: const Icon(Icons.call_outlined),
                          label: Text('Llamar: ${church.phone}'),
                        ),
                      ),
                    if (church.phone.isNotEmpty && church.whatsapp.isNotEmpty)
                      const SizedBox(height: 10),
                    if (church.whatsapp.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openWhatsApp(context, church!.whatsapp),
                          icon: const Icon(Icons.message_outlined),
                          label: Text('WhatsApp: ${church.whatsapp}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}