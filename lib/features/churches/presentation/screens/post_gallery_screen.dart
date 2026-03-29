import 'package:flutter/material.dart';

class PostGalleryScreen extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const PostGalleryScreen({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final controller = PageController(initialPage: initialIndex);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: PageView.builder(
        controller: controller,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Center(
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}