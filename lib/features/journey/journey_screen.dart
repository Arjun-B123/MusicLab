import 'package:flutter/material.dart';

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journey')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Your musical timeline — milestones, learned pieces, and '
            'memories — will live here.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
