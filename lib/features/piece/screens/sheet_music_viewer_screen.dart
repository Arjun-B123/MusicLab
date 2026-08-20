import 'package:flutter/material.dart';

/// Full-screen sheet music viewer — display only (pinch-to-zoom), no note
/// detection. Extracting structured note data from an image is a separate,
/// much harder problem (see Piece.hasTutorialData) and isn't attempted here.
class SheetMusicViewerScreen extends StatelessWidget {
  const SheetMusicViewerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Center(
          child: Image.network(
            url,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (context, error, stack) => Center(
              child: Text(
                "Couldn't load this image: $error",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
