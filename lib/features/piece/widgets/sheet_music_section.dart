import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../analysis/omr_repository.dart';
import '../models/piece.dart';
import '../piece_repository.dart';
import '../screens/sheet_music_viewer_screen.dart';

const _commonTimeSignatures = [
  '4/4',
  '3/4',
  '2/4',
  '2/2',
  '6/8',
  '9/8',
  '12/8',
];

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
  final _omrRepository = OmrRepository();
  final _imagePicker = ImagePicker();
  bool _busy = false;
  bool _detectingTimeSignature = false;

  bool get _isPdf => widget.piece.sheetMusicPath?.endsWith('.pdf') ?? false;

  Future<void> _upload(File file, String extension) async {
    setState(() => _busy = true);
    try {
      final updated = await _repository.attachSheetMusic(
        piece: widget.piece,
        file: file,
        extension: extension,
      );
      widget.onPieceUpdated(updated);
      unawaited(_detectAndConfirmTimeSignature(file, extension));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Couldn't attach that file: $e")));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _detectAndConfirmTimeSignature(
    File file,
    String extension,
  ) async {
    setState(() => _detectingTimeSignature = true);
    String? detected;
    try {
      detected = await _omrRepository.detectTimeSignature(file, extension);
    } catch (_) {
      detected = null;
    }
    if (mounted) setState(() => _detectingTimeSignature = false);
    if (!mounted) return;
    await _editTimeSignature(suggested: detected);
  }

  Future<void> _editTimeSignature({String? suggested}) async {
    var selected = suggested ?? widget.piece.timeSignature;
    if (!_commonTimeSignatures.contains(selected)) selected = '4/4';

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Time signature'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (suggested != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Detected from your sheet music — double-check it, '
                        "this can be wrong on photos that are hard to read.",
                        style: Theme.of(dialogContext).textTheme.bodySmall,
                      ),
                    )
                  else if (suggested == null &&
                      _detectingTimeSignature == false)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        "Couldn't detect this automatically — set it manually.",
                        style: Theme.of(dialogContext).textTheme.bodySmall,
                      ),
                    ),
                  DropdownButton<String>(
                    value: selected,
                    isExpanded: true,
                    items: _commonTimeSignatures
                        .map(
                          (ts) => DropdownMenuItem(value: ts, child: Text(ts)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selected = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(selected),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    try {
      final updated = await _repository.setTimeSignature(
        widget.piece.id,
        result,
      );
      widget.onPieceUpdated(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't save time signature: $e")),
      );
    }
  }

  Future<void> _pickPhoto() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    await _upload(File(image.path), image.path.split('.').last.toLowerCase());
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    await _upload(File(path), 'pdf');
  }

  Future<void> _showAttachOptions() async {
    final colors = context.colors;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Photo'),
                onTap: () => Navigator.of(sheetContext).pop('photo'),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('PDF'),
                onTap: () => Navigator.of(sheetContext).pop('pdf'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (choice == 'photo') {
      await _pickPhoto();
    } else if (choice == 'pdf') {
      await _pickPdf();
    }
  }

  Future<void> _searchForSheetMusic() async {
    final query = Uri.encodeComponent('${widget.piece.title} sheet music');
    final uri = Uri.parse('https://www.google.com/search?q=$query');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _view() async {
    final path = widget.piece.sheetMusicPath;
    if (path == null) return;
    final url = await _repository.sheetMusicUrl(path);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SheetMusicViewerScreen(
          url: url,
          title: widget.piece.title,
          isPdf: _isPdf,
        ),
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
                    icon: Icon(
                      _isPdf
                          ? Icons.picture_as_pdf_outlined
                          : Icons.image_outlined,
                    ),
                    label: const Text('View'),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: _busy ? null : _showAttachOptions,
                  child: const Text('Replace'),
                ),
              ],
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _showAttachOptions,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(_busy ? 'Uploading…' : 'Attach sheet music'),
              ),
            ),
            if (widget.piece.referenceRecordingId == null) ...[
              const SizedBox(height: 8),
              Text(
                "Learning from a video or don't have sheet music? Record a "
                'correct take below and set it as this piece\'s reference — '
                "that's what your takes get compared against.",
                style: TextStyle(fontSize: 13, color: colors.onBackgroundSoft),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: _searchForSheetMusic,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Search for sheet music online'),
              ),
            ],
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 18,
                color: colors.onBackgroundSoft,
              ),
              const SizedBox(width: 6),
              Text(
                'Time signature: ${widget.piece.timeSignature}',
                style: TextStyle(color: colors.onBackgroundSoft),
              ),
              const Spacer(),
              if (_detectingTimeSignature)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit time signature',
                  onPressed: () => _editTimeSignature(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
