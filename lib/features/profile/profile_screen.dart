import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/purchases/paywall_helpers.dart';
import '../../core/purchases/subscription_status.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/moon_icon.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../paywall/screens/pro_features_intro_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _busy = false;

  Future<void> _handleUpgrade() async {
    final unlocked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const ProFeaturesIntroScreen(),
        fullscreenDialog: true,
      ),
    );
    if (!mounted) return;
    if (unlocked == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You're on MusicLab Pro. Welcome!")),
      );
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

  Future<void> _handleSignOut() async {
    final user = Supabase.instance.client.auth.currentUser;
    final isAnonymous = user?.isAnonymous ?? true;

    // There's no login screen yet, so an anonymous account has no way back
    // in after signing out — everything (pieces, recordings) becomes
    // unreachable. Confirm explicitly rather than let that happen by
    // accident.
    if (isAnonymous) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign out?'),
          content: const Text(
            "This account isn't linked to an email yet, so signing out "
            "means there's no way back to your pieces and recordings. "
            "This can't be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sign out anyway'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subscription = context.watch<SubscriptionStatus>();
    final user = Supabase.instance.client.auth.currentUser;
    final isAnonymous = user?.isAnonymous ?? true;
    final joined = user != null
        ? DateFormat('MMM yyyy').format(DateTime.parse(user.createdAt))
        : null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PROFILE',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: colors.sage,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAnonymous
                        ? 'Your account'
                        : (user?.email ?? 'Your account'),
                    style: AppTheme.handwritten(
                      size: 27,
                      color: colors.onBackground,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colors.surfaceBorder,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: colors.onBackgroundFaint,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAnonymous
                              ? 'Anonymous account'
                              : (user?.email ?? ''),
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.handwritten(
                            size: 15,
                            color: colors.onBackground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          joined != null ? 'Piano · joined $joined' : 'Piano',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: colors.onBackgroundFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: subscription.isPro
                  ? _ProCard(
                      colors: colors,
                      busy: _busy,
                      onManage: () => presentCustomerCenter(context),
                    )
                  : _FreeCard(
                      colors: colors,
                      busy: _busy,
                      onUpgrade: _handleUpgrade,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.surfaceBorder, width: 2),
                ),
                child: Column(
                  children: [
                    const _ThemeToggleRow(),
                    _MenuRow(
                      icon: Icons.refresh,
                      label: 'Restore purchases',
                      colors: colors,
                      showDivider: true,
                      onTap: _busy ? null : _handleRestore,
                    ),
                    if (subscription.isPro)
                      _MenuRow(
                        icon: Icons.settings_outlined,
                        label: 'Manage subscription',
                        colors: colors,
                        showDivider: true,
                        onTap: _busy
                            ? null
                            : () => presentCustomerCenter(context),
                      ),
                    _MenuRow(
                      icon: Icons.logout,
                      label: 'Sign out',
                      colors: colors,
                      showDivider: false,
                      onTap: _handleSignOut,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProCard extends StatelessWidget {
  const _ProCard({
    required this.colors,
    required this.busy,
    required this.onManage,
  });
  final AppColors colors;
  final bool busy;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.accent, colors.accentDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR PLAN',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 1.1,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'MusicLab Pro',
            style: AppTheme.handwritten(size: 22, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            'Thanks for supporting MusicLab',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: colors.accentDark,
            ),
            onPressed: busy ? null : onManage,
            child: const Text('Manage subscription'),
          ),
        ],
      ),
    );
  }
}

class _FreeCard extends StatelessWidget {
  const _FreeCard({
    required this.colors,
    required this.busy,
    required this.onUpgrade,
  });
  final AppColors colors;
  final bool busy;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.surfaceBorder, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR PLAN',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 1.1,
              color: colors.accentOnSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Free',
            style: AppTheme.handwritten(size: 22, color: colors.ink),
          ),
          const SizedBox(height: 2),
          Text(
            'Upgrade for unlimited pieces, full analysis, and recording history',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: colors.inkSoft,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy ? null : onUpgrade,
            child: const Text('Upgrade to Pro →'),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggleRow extends StatelessWidget {
  const _ThemeToggleRow();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = context.watch<ThemeModeController>();

    return InkWell(
      onTap: () => controller.toggle(Theme.of(context).brightness),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.surfaceBorder)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => RotationTransition(
                  turns: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: KeyedSubtree(
                  key: ValueKey(isDark),
                  child: isDark
                      ? MoonIcon(size: 18, color: colors.accent)
                      : Icon(
                          Icons.wb_sunny_rounded,
                          size: 18,
                          color: colors.accent,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isDark ? 'Dark mode' : 'Light mode',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: colors.ink,
                ),
              ),
            ),
            Switch(
              value: isDark,
              onChanged: (_) => controller.toggle(Theme.of(context).brightness),
              // This row sits on a colors.surface card, and in dark mode
              // colors.accent IS colors.surface (same orange) — using
              // accent here made the whole switch blend into the card.
              // accentOnSurface is the contrasting color for exactly this
              // situation (see AppColors doc comment).
              activeThumbColor: colors.accentOnSurface,
              activeTrackColor: colors.accentOnSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.colors,
    required this.showDivider,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final AppColors colors;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: colors.surfaceBorder))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: colors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: colors.ink,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: colors.tabInactive),
          ],
        ),
      ),
    );
  }
}
