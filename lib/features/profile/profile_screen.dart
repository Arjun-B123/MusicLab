import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/purchases/paywall_helpers.dart';
import '../../core/purchases/subscription_status.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _busy = false;

  Future<void> _handleUpgrade() async {
    setState(() => _busy = true);
    try {
      final unlocked = await presentProPaywallIfNeeded(context);
      if (!mounted) return;
      if (unlocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You're on MusicLab Pro. Welcome!")),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _busy = true);
    try {
      await context.read<SubscriptionStatus>().restorePurchases();
      if (!mounted) return;
      final isPro = context.read<SubscriptionStatus>().isPro;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPro
                ? 'Purchases restored — MusicLab Pro is active.'
                : 'No active MusicLab Pro purchase found for this account.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't restore purchases. Try again.")),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionStatus>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                subscription.isPro ? Icons.workspace_premium : Icons.piano,
                color: subscription.isPro
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(
                subscription.isPro ? 'MusicLab Pro' : 'Free plan',
              ),
              subtitle: Text(
                subscription.isPro
                    ? 'Thanks for supporting MusicLab.'
                    : 'Upgrade for unlimited pieces and advanced analysis.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!subscription.isPro)
            FilledButton.icon(
              onPressed: _busy ? null : _handleUpgrade,
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('Upgrade to MusicLab Pro'),
            ),
          if (subscription.isPro)
            OutlinedButton.icon(
              onPressed: _busy ? null : () => presentCustomerCenter(context),
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Manage subscription'),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : _handleRestore,
            child: const Text('Restore purchases'),
          ),
          const Divider(height: 32),
          const ListTile(
            leading: Icon(Icons.piano_outlined),
            title: Text('Instruments'),
            subtitle: Text('Coming soon'),
          ),
          const ListTile(
            leading: Icon(Icons.flag_outlined),
            title: Text('Goals'),
            subtitle: Text('Coming soon'),
          ),
        ],
      ),
    );
  }
}
