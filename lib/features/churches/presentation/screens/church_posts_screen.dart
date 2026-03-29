import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/data/church_posts_service.dart';
import 'package:red_cristiana/features/churches/presentation/screens/post_gallery_screen.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/post_images_widget.dart';

class ChurchPostsScreen extends StatefulWidget {
  final String churchId;
  final String churchName;

  const ChurchPostsScreen({
    super.key,
    required this.churchId,
    required this.churchName,
  });

  @override
  State<ChurchPostsScreen> createState() => _ChurchPostsScreenState();
}

class _ChurchPostsScreenState extends State<ChurchPostsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final data = await ChurchPostsService.getChurchPosts(widget.churchId);

      if (!mounted) return;
      setState(() {
        posts = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _togglePostLike(String postId) async {
    await ChurchPostsService.togglePostLike(postId);
    await _loadPosts();
  }

  Widget _postCard(Map<String, dynamic> post) {
    final title = post['title']?.toString() ?? '';
    final content = post['content']?.toString() ?? '';
    final likes = post['likes_count'] ?? 0;
    final liked = post['liked_by_me'] ?? false;
    final images = List<Map<String, dynamic>>.from(post['images'] ?? []);

    final urls = images
        .map((e) => e['image_url']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

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
          PostImagesWidget(imageUrls: urls),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (title.isNotEmpty && content.isNotEmpty)
                  const SizedBox(height: 8),
                if (content.isNotEmpty)
                  Text(
                    content,
                    style: const TextStyle(height: 1.45),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _togglePostLike(post['id'].toString()),
                      icon: Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        color: liked ? Colors.red : Colors.black54,
                      ),
                    ),
                    Text('$likes Me gusta'),
                  ],
                ),
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
        title: Text('Publicaciones de ${widget.churchName}'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
          ? const Center(
        child: Text('No hay publicaciones disponibles.'),
      )
          : RefreshIndicator(
        onRefresh: _loadPosts,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) => _postCard(posts[index]),
        ),
      ),
    );
  }
}