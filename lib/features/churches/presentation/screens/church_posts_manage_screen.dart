import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:red_cristiana/features/churches/data/church_posts_service.dart';
import 'package:red_cristiana/features/churches/presentation/screens/post_gallery_screen.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/church_header_shell.dart';
import 'package:red_cristiana/features/churches/presentation/widgets/post_images_widget.dart';

class ChurchPostsManageScreen extends StatefulWidget {
  const ChurchPostsManageScreen({super.key});

  @override
  State<ChurchPostsManageScreen> createState() => _ChurchPostsManageScreenState();
}

class _ChurchPostsManageScreenState extends State<ChurchPostsManageScreen> {
  static const Color _primary = Color(0xFF0D47A1);
  static const Color _primaryLight = Color(0xFF1565C0);
  static const Color _surface = Color(0xFFF4F7FB);
  static const Color _card = Colors.white;
  static const Color _textDark = Color(0xFF152033);
  static const Color _textSoft = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE6EDF6);

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

  Future<void> _openCreateSheet() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    final pickedImages = <XFile>[];
    final imageBytesList = <Uint8List>[];

    final formKey = GlobalKey<FormState>();
    bool saving = false;

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickImages() async {
              final picked = await picker.pickMultiImage();
              if (picked.isEmpty) return;

              final merged = <XFile>[...pickedImages];

              for (final image in picked) {
                if (merged.length >= 6) break;
                merged.add(image);
              }

              final bytes = <Uint8List>[];
              for (final img in merged) {
                bytes.add(await img.readAsBytes());
              }

              setSheetState(() {
                pickedImages
                  ..clear()
                  ..addAll(merged);
                imageBytesList
                  ..clear()
                  ..addAll(bytes);
              });
            }

            void removeImage(int index) {
              setSheetState(() {
                pickedImages.removeAt(index);
                imageBytesList.removeAt(index);
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
                                  'Nueva publicación',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Comparte mensajes, novedades, fotos y contenido visual para tu comunidad.',
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
                                  children: const [
                                    _TopChip(
                                      icon: Icons.edit_note_outlined,
                                      text: 'Mensaje',
                                    ),
                                    _TopChip(
                                      icon: Icons.photo_library_outlined,
                                      text: 'Hasta 6 imágenes',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Contenido',
                            style: TextStyle(
                              color: _textDark,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: titleController,
                            decoration: decoration(
                              'Título opcional',
                              Icons.title_outlined,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: contentController,
                            maxLines: 5,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Escribe un mensaje o descripción'
                                : null,
                            decoration: decoration(
                              'Mensaje',
                              Icons.edit_note_outlined,
                            ).copyWith(
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Imágenes',
                                  style: TextStyle(
                                    color: _textDark,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF2FF),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${pickedImages.length}/6',
                                  style: const TextStyle(
                                    color: _primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: pickImages,
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: _border),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 42,
                                    color: _primary,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Seleccionar imágenes',
                                    style: TextStyle(
                                      color: _textDark,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pickedImages.isEmpty
                                        ? 'Puedes agregar hasta 6 imágenes'
                                        : 'Toca aquí para agregar más',
                                    style: const TextStyle(
                                      color: _textSoft,
                                      fontSize: 12.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (imageBytesList.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: imageBytesList.length,
                              gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.memory(
                                        imageBytesList[index],
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Material(
                                        color: Colors.black.withValues(alpha: 0.45),
                                        borderRadius: BorderRadius.circular(999),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(999),
                                          onTap: () => removeImage(index),
                                          child: const Padding(
                                            padding: EdgeInsets.all(6),
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
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

                                      final myChurch =
                                      await ChurchPostsService.getMyChurch();
                                      if (myChurch == null) {
                                        throw Exception(
                                          'No se encontró la iglesia',
                                        );
                                      }

                                      final uploadedUrls = <String>[];

                                      for (int i = 0;
                                      i < pickedImages.length;
                                      i++) {
                                        final url = await ChurchPostsService
                                            .uploadPostImage(
                                          filePath: pickedImages[i].path,
                                          bytes: imageBytesList[i],
                                          churchId: myChurch['id'].toString(),
                                        );
                                        uploadedUrls.add(url);
                                      }

                                      await ChurchPostsService.createPost(
                                        churchId: myChurch['id'].toString(),
                                        title: titleController.text.trim(),
                                        content:
                                        contentController.text.trim(),
                                        imageUrls: uploadedUrls,
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
                                            'Error creando publicación: $e',
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
                                    saving ? 'Publicando...' : 'Publicar',
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
      await _loadPosts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publicación creada correctamente'),
        ),
      );
    }

    titleController.dispose();
    contentController.dispose();
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

  Future<void> _confirmDelete(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Eliminar publicación'),
          content: const Text(
            '¿Seguro que deseas eliminar esta publicación?',
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
      await _deletePost(postId);
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
            'Publicaciones',
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
              _chipTop(
                icon: Icons.feed_outlined,
                text: '${posts.length} total',
              ),
              const _TopChip(
                icon: Icons.photo_library_outlined,
                text: 'Fotos y mensajes',
              ),
              const _TopChip(
                icon: Icons.auto_awesome_outlined,
                text: 'Contenido visual',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipTop({
    required IconData icon,
    required String text,
  }) {
    return _TopChip(icon: icon, text: text);
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
              Icons.post_add_outlined,
              color: _primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              posts.isEmpty
                  ? 'Todavía no hay publicaciones creadas.'
                  : (posts.length == 1
                  ? 'Tienes 1 publicación creada.'
                  : 'Tienes ${posts.length} publicaciones creadas.'),
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

  Widget _postCard(Map<String, dynamic> post) {
    final title = post['title']?.toString().trim() ?? '';
    final content = post['content']?.toString().trim() ?? '';
    final createdAt = post['created_at']?.toString().trim() ?? '';
    final images = List<Map<String, dynamic>>.from(post['images'] ?? []);

    final urls = images
        .map((e) => e['image_url']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    final postId = post['id']?.toString() ?? '';

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
          if (urls.isNotEmpty) PostImagesWidget(imageUrls: urls),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (createdAt.isNotEmpty)
                            _InfoChip(
                              icon: Icons.calendar_today_outlined,
                              text: _formatDateForDisplay(createdAt),
                              bgColor: const Color(0xFFEAF2FF),
                              textColor: _primary,
                            ),
                          _InfoChip(
                            icon: Icons.photo_library_outlined,
                            text: urls.isEmpty
                                ? 'Sin imágenes'
                                : '${urls.length} imagen${urls.length == 1 ? '' : 'es'}',
                            bgColor: const Color(0xFFE8F5E9),
                            textColor: const Color(0xFF2E7D32),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: const Color(0xFFF4F7FB),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: postId.isEmpty ? null : () => _confirmDelete(postId),
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
                  ],
                ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ],
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    content,
                    style: const TextStyle(
                      color: _textSoft,
                      fontSize: 13.4,
                      height: 1.45,
                    ),
                  ),
                ],
                if (urls.length > 1) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostGalleryScreen(
                            imageUrls: urls,
                            initialIndex: 0,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F8FC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.collections_outlined,
                            size: 18,
                            color: _primary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Ver galería completa',
                            style: TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
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
              Icons.photo_library_outlined,
              size: 38,
              color: _primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Todavía no has publicado contenido',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Comparte mensajes, reflexiones, anuncios e imágenes para mantener activa a tu comunidad.',
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
                'Crear primera publicación',
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
      onRefresh: _loadPosts,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _heroCard(),
          const SizedBox(height: 18),
          _sectionTitle(
            'Resumen',
            'Gestiona publicaciones, mensajes e imágenes de tu iglesia.',
          ),
          _summaryCard(),
          const SizedBox(height: 20),
          _sectionTitle(
            'Listado de publicaciones',
            'Aquí aparecen todos los contenidos publicados.',
          ),
          if (posts.isEmpty) _emptyState() else ...posts.map(_postCard),
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
            'Nueva publicación',
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color bgColor;
  final Color textColor;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
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
}