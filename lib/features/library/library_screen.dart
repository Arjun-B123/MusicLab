import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/progress_ring.dart';
import '../piece/models/piece.dart';
import '../piece/piece_repository.dart';
import '../piece/screens/piece_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _repository = PieceRepository();
  late Future<List<Piece>> _piecesFuture;

  @override
  void initState() {
    super.initState();
    _piecesFuture = _repository.fetchPieces();
  }

  void _refresh() => setState(() => _piecesFuture = _repository.fetchPieces());

  Future<void> _showAddPieceSheet() async {
    final colors = context.colors;
    final titleController = TextEditingController();
    final goalController = TextEditingController();

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 22,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 22,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colors.surfaceBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Text('Add a piece', style: AppTheme.handwritten(size: 22, color: colors.ink)),
              _FieldLabel('Title', colors),
              _AddPieceField(controller: titleController, hint: 'e.g. Für Elise', colors: colors),
              _FieldLabel('Instrument', colors),
              const SizedBox(height: 6),
              // Piano-only for now, matches the current build's scope.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Piano',
                  style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13, color: colors.onAccent),
                ),
              ),
              _FieldLabel('Goal (optional)', colors),
              _AddPieceField(
                controller: goalController,
                hint: "e.g. Play it for grandma's birthday",
                colors: colors,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  child: const Text('Add piece'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (created != true) return;
    if (titleController.text.trim().isEmpty) return;

    try {
      await _repository.createPiece(
        title: titleController.text.trim(),
        instrument: 'piano',
        goal: goalController.text.trim().isEmpty ? null : goalController.text.trim(),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't add that piece: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: FutureBuilder<List<Piece>>(
        future: _piecesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text("Couldn't load your pieces: ${snapshot.error}"),
              ),
            );
          }

          final pieces = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LIBRARY',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: colors.sage,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Your pieces', style: AppTheme.handwritten(size: 27, color: colors.ink)),
                        ],
                      ),
                      FilledButton(
                        onPressed: _showAddPieceSheet,
                        child: const Text('+ Add'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 4),
                  child: Text(
                    '${pieces.length} piece${pieces.length == 1 ? '' : 's'} · Piano',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: colors.inkFaint),
                  ),
                ),
                if (pieces.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 40, 22, 20),
                    child: Text(
                      "No pieces yet — tap + Add to add the one you're learning.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.inkSoft),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                    child: Column(
                      children: [
                        for (final piece in pieces)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PieceRow(
                              piece: piece,
                              colors: colors,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PieceDetailScreen(piece: piece),
                                  ),
                                );
                                _refresh();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, this.colors);
  final String label;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.6,
          color: colors.inkSoft,
        ),
      ),
    );
  }
}

class _AddPieceField extends StatelessWidget {
  const _AddPieceField({required this.controller, required this.hint, required this.colors});
  final TextEditingController controller;
  final String hint;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: TextField(
        controller: controller,
        style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: colors.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 14, color: colors.inkFaint),
          filled: true,
          fillColor: colors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.surfaceBorder, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.surfaceBorder, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.accent, width: 2),
          ),
        ),
      ),
    );
  }
}

class _PieceRow extends StatelessWidget {
  const _PieceRow({required this.piece, required this.colors, required this.onTap});

  final Piece piece;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dotColor = piece.status == PieceStatus.learned ? colors.accent : colors.gold;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.surfaceBorder, width: 2),
        ),
        child: Row(
          children: [
            ProgressRing(
              progress: piece.approximateProgress,
              size: 46,
              strokeWidth: 5,
              trackColor: colors.surfaceBorder,
              progressColor: colors.accent,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    piece.title,
                    style: AppTheme.handwritten(size: 16, color: colors.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    piece.goal != null
                        ? '${piece.instrument} · goal: ${piece.goal}'
                        : piece.instrument,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: colors.inkFaint),
                  ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
            ),
          ],
        ),
      ),
    );
  }
}
