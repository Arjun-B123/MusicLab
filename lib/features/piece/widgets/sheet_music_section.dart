import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../models/piece.dart';
import '../piece_repository.dart';
import '../screens/sheet_music_viewer_screen.dart';

class SheetMusicSection extends StatefulWidget {
  const SheetMusicSection({
    super.key,
    required this.piece,
    required this.onPieceUpdated,
  });

  final Piece piece;
  final ValueChanged<Piece> onPieceUpdated;

  @override
  State<SheetMusicSection> createState() => _SheetMusicSectionState();
}

class _SheetMusicSectionState extends State<SheetMusicSection> {
  final _repository = PieceRepository();
  final _picker = ImagePicker();
  bool _busy = false;

  Future<void> _pickAndUpload() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final extension = image.path.split('.').last.toLowerCase();
    setState(() => _busy = true);
    try {
      final updated = await _repository.attachSheetMusic(
        piece: widget.piece,
        file: File(image.path),
        extension: extension,
      );
      widget.onPieceUpdated(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't attach that image: $e")),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _view() async {
    final path = widget.piece.sheetMusicPath;
    if (path == null) return;
    final url = await _repository.sheetMusicUrl(path);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SheetMusicViewerScreen(url: url, title: widget.piece.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasSheetMusic = widget.piece.sheetMusicPath != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.surfaceBorder, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sheet music',
            style: AppTheme.handwritten(size: 17, color: colors.ink),
          ),
          const SizedBox(height: 10),
          if (hasSheetMusic)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _view,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('View'),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: _busy ? null : _pickAndUpload,
                  child: const Text('Replace'),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _pickAndUpload,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(_busy ? 'Uploading…' : 'Attach sheet music (photo)'),
              ),
            ),
        ],
      ),
    );
  }
}
