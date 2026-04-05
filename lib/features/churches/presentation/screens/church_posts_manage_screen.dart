import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:red_cristiana/features/churches/data/church_posts_service.dart';
import 'package:red_cristiana/features/churches/presentation/screens/post_gallery_screen.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/post_images_widget.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/church_header_shell.dart';

class ChurchPostsManageScreen extends StatefulWidget {
  const ChurchPostsManageScreen({super.key});

  @override
  State<ChurchPostsManageScreen> createState() =>
      _ChurchPostsManageScreenState();
}

class _ChurchPostsManageScreenState extends State<ChurchPostsManageScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> posts = [];
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final data = await ChurchPostsService.getMyPosts();

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando publicaciones: $e')),
      );
    }
  }

  Future<void> _openCreateDialog() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    final pickedImages = <XFile>[];
    final imageBytesList = <Uint8List>[];

    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImages() async {
              final picked = await picker.pickMultiImage();
              if (picked.isEmpty) return;

              final limited = picked.take(6).toList();
              final bytes = <Uint8List>[];

              for (final img in limited) {
                bytes.add(await img.readAsBytes());
              }

              setDialogState(() {
                pickedImages
                  ..clear()
                  ..addAll(limited);
                imageBytesList
                  ..clear()
                  ..addAll(bytes);
              });
            }

            return AlertDialog(
              title: const Text('Nueva publicación'),
              content: SizedBox(
                width: 430,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleController,
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
                          controller: contentController,
                          maxLines: 4,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Escribe un mensaje o descripción'
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Mensaje',
                            prefixIcon: const Icon(Icons.edit_note),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: pickImages,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Seleccionar hasta 6 imágenes'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (imageBytesList.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(
                              imageBytesList.length,
                                  (index) => ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  imageBytesList[index],
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
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
                      setDialogState(() {
                        saving = true;
                      });

                      final myChurch = await ChurchPostsService.getMyChurch();
                      if (myChurch == null) {
                        throw Exception('No se encontró la iglesia');
                      }

                      final uploadedUrls = <String>[];

                      for (int i = 0; i < pickedImages.length; i++) {
                        final url = await ChurchPostsService.uploadPostImage(
                          filePath: pickedImages[i].path,
                          bytes: imageBytesList[i],
                          churchId: myChurch['id'].toString(),
                        );
                        uploadedUrls.add(url);
                      }

                      await ChurchPostsService.createPost(
                        churchId: myChurch['id'].toString(),
                        title: titleController.text.trim(),
                        content: contentController.text.trim(),
                        imageUrls: uploadedUrls,
                      );

                      if (!mounted) return;
                      Navigator.pop(dialogContext);
                      await _loadPosts();

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Publicación creada correctamente'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      setDialogState(() {
                        saving = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error creando publicación: $e')),
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

  Widget _buildImagesGrid(List<Map<String, dynamic>> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    final urls = images
        .map((e) => e['image_url']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    if (urls.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: urls.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostGalleryScreen(
                    imageUrls: urls,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                urls[index],
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _postCard(Map<String, dynamic> post) {
    final title = post['title']?.toString() ?? '';
    final content = post['content']?.toString() ?? '';
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
                Text(
                  content,
                  style: const TextStyle(
                    color: Colors.black87,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(String postId) async {
    try {
      await ChurchPostsService.deletePost(postId);
      await _loadPosts();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación eliminada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error eliminando publicación: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChurchHeaderShell(
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
        title: const Text('Publicaciones de mi iglesia'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
          ? const Center(
        child: Text('Aún no has publicado nada.'),
      )
          : RefreshIndicator(
        onRefresh: _loadPosts,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Stack(
              children: [
                _postCard(post),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton.filled(
                    onPressed: () => _deletePost(post['id'].toString()),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ],
            );
          },
        ),
      ),
        ),
    );
  }
}