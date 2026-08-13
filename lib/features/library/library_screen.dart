import 'package:flutter/material.dart';

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

  void _refresh() {
    setState(() => _piecesFuture = _repository.fetchPieces());
  }

  Future<void> _showAddPieceDialog() async {
    final titleController = TextEditingController();
    final goalController = TextEditingController();
    String instrument = 'piano';

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add a piece'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: instrument,
                decoration: const InputDecoration(labelText: 'Instrument'),
                // Piano-only for now — matches the current build's scope;
                // other instruments come later.
                items: const [
                  DropdownMenuItem(value: 'piano', child: Text('Piano')),
                ],
                onChanged: (value) =>
                    setDialogState(() => instrument = value ?? 'piano'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: goalController,
                decoration: const InputDecoration(
                  labelText: 'Goal (optional)',
                  hintText: 'e.g. Learn and perform this piece',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: titleController.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(context).pop(true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (created != true) return;

    try {
      await _repository.createPiece(
        title: titleController.text.trim(),
        instrument: instrument,
        goal: goalController.text.trim().isEmpty
            ? null
            : goalController.text.trim(),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
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
          if (pieces.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "No pieces yet — tap + to add the one you're learning.",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              itemCount: pieces.length,
              itemBuilder: (context, index) {
                final piece = pieces[index];
                return ListTile(
                  leading: const Icon(Icons.piano_outlined),
                  title: Text(piece.title),
                  subtitle: Text(
                    [
                      piece.instrument,
                      piece.status.label,
                      if (piece.hasTutorialData) 'tutorial available',
                    ].join(' · '),
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            PieceDetailScreen(piece: piece),
                      ),
                    );
                    _refresh();
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPieceDialog,
        tooltip: 'Add a piece',
        child: const Icon(Icons.add),
      ),
    );
  }
}
