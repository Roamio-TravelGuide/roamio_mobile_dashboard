import 'package:flutter/material.dart';

class GalleryPage extends StatelessWidget {
  final String title;
  final List<String>? photos; // For backward compatibility
  final List<Map<String, dynamic>>? galleryItems; // New structure with titles

  const GalleryPage({super.key, required this.title, this.photos, this.galleryItems});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12), // Explicitly set dark background
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
        ],
        backgroundColor: const Color(0xFF0D0D12), // Explicitly set dark background
        surfaceTintColor: Colors.transparent, // Remove any tint
        shadowColor: Colors.transparent, // Remove shadow
        foregroundColor: Colors.white, // Ensure all text/icons are white
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: galleryItems != null ? galleryItems!.length : (photos?.length ?? 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          String url;
          String? itemTitle;

          if (galleryItems != null) {
            url = galleryItems![index]['image'];
            itemTitle = galleryItems![index]['title'];
          } else {
            url = photos![index];
            itemTitle = null;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (itemTitle != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Text(
                    itemTitle,
                    style: const TextStyle(
                      color: Colors.white, // White text for stop names
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.white10,
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade700),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
