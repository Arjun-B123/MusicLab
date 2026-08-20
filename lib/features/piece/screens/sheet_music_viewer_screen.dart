import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

/// Full-screen sheet music viewer — display only (pinch-to-zoom for images,
/// scrollable pages for PDFs), no note detection. Extracting structured
/// note data from a PDF/image is a separate, much harder problem (see
/// Piece.hasTutorialData) and isn't attempted here.
class SheetMusicViewerScreen extends StatefulWidget {
  const SheetMusicViewerScreen({
    super.key,
    required this.url,
    required this.title,
    required this.isPdf,
  });

  final String url;
  final String title;
  final bool isPdf;

  @override
  State<SheetMusicViewerScreen> createState() =>
      _SheetMusicViewerScreenState();
}

class _SheetMusicViewerScreenState extends State<SheetMusicViewerScreen> {
  PdfController? _pdfController;

  @override
  void initState() {
    super.initState();
    if (widget.isPdf) {
      _pdfController = PdfController(
        document: PdfDocument.openData(http.readBytes(Uri.parse(widget.url))),
      );
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: widget.isPdf
          ? PdfView(controller: _pdfController!, scrollDirection: Axis.vertical)
          : InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  widget.url,
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
