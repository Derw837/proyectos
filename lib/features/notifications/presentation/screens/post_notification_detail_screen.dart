import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/data/models/church_model.dart';
import 'package:red_cristiana/features/churches/presentation/screens/church_detail_screen.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/post_images_widget.dart';

class PostNotificationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostNotificationDetailScreen({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    final title = post['title']?.toString() ?? '';
    final content = post['content']?.toString() ?? '';
    final createdAt = post['created_at']?.toString() ?? '';

    final images = List<Map<String, dynamic>>.from(post['images'] ?? []);
    final imageUrls = images
        .map((e) => e['image_url']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    final churchData = post['churches'];
    ChurchModel? church;
    if (churchData is Map<String, dynamic>) {
      church = ChurchModel.fromMap(churchData);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Publicación'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            if (imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  color: Colors.white,
                  child: PostImagesWidget(imageUrls: imageUrls),
                ),
              ),
            if (imageUrls.isNotEmpty) const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0D47A1),
                    Color(0xFF1565C0),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Publicación',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title.isEmpty ? 'Publicación de iglesia' : title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  if (createdAt.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      createdAt.split('T').first,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (content.isNotEmpty) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  content,
                  style: const TextStyle(
                    color: Colors.black87,
                    height: 1.5,
                    fontSize: 15.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}