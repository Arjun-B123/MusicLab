import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "Today's practice, current pieces, and recent progress will "
            'live here.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
