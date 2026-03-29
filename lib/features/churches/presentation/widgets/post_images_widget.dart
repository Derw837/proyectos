import 'package:flutter/material.dart';
import 'package:red_cristiana/features/churches/presentation/screens/post_gallery_screen.dart';

class PostImagesWidget extends StatelessWidget {
  final List<String> imageUrls;

  const PostImagesWidget({
    super.key,
    required this.imageUrls,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    if (imageUrls.length == 1) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostGalleryScreen(
                  imageUrls: imageUrls,
                  initialIndex: 0,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrls.first,
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: imageUrls.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostGalleryScreen(
                    imageUrls: imageUrls,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}