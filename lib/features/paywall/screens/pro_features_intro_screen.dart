import 'package:flutter/material.dart';

import '../../../core/purchases/paywall_helpers.dart';
import '../../../core/theme/app_theme.dart';

class _FeaturePage {
  const _FeaturePage({
    required this.icon,
    required this.headline,
    required this.body,
  });

  final IconData icon;
  final String headline;
  final String body;
}

const _pages = [
  _FeaturePage(
    icon: Icons.auto_awesome_outlined,
    headline: "See how far you've come.",
    body:
        'MusicLab Pro unlocks the full picture of your practice — not just '
        'that you practiced, but whether you actually improved.',
  ),
  _FeaturePage(
    icon: Icons.bar_chart_rounded,
    headline: 'Know exactly what to fix.',
    body:
        'Bar-by-bar feedback on your playing — not just a score, but '
        'specifically where things went off and what to practice next.',
  ),
  _FeaturePage(
    icon: Icons.library_music_outlined,
    headline: 'Every piece, in one place.',
    body:
        'Free is capped at 3 pieces — Pro removes the limit, so your whole '
        'repertoire lives in your library.',
  ),
  _FeaturePage(
    icon: Icons.history_rounded,
    headline: 'Hear how far you\'ve come.',
    body:
        'Free keeps your last 5 takes. Pro keeps everything — compare your '
        'first take to your latest and actually hear the improvement.',
  ),
  _FeaturePage(
    icon: Icons.tips_and_updates_outlined,
    headline: 'A plan that knows your weak spots.',
    body:
        'Pro turns your last analysis into a specific plan — which section, '
        'which hand, what tempo — instead of generic reminders.',
  ),
  _FeaturePage(
    icon: Icons.timeline_rounded,
    headline: 'Your whole musical story.',
    body:
        'Free shows your last 30 days. Pro keeps your entire journey — '
        'every piece, every milestone, from day one.',
  ),
];

/// A short, native feature-showcase flow shown before the actual RevenueCat
/// paywall — one screen per Pro feature, ending by handing off to whatever
/// paywall is configured in the RevenueCat dashboard. This flow itself is
/// plain Flutter, not RevenueCat-hosted; only the final purchase screen is.
class ProFeaturesIntroScreen extends StatefulWidget {
  const ProFeaturesIntroScreen({super.key});

  @override
  State<ProFeaturesIntroScreen> createState() =>
      _ProFeaturesIntroScreenState();
}

class _ProFeaturesIntroScreenState extends State<ProFeaturesIntroScreen> {
  final _controller = PageController();
  int _index = 0;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLastPage => _index == _pages.length - 1;

  void _next() {
    if (_isLastPage) {
      _goToPaywall();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _goToPaywall() async {
    setState(() => _busy = true);
    try {
      final unlocked = await presentProPaywallIfNeeded(context);
      if (!mounted) return;
      Navigator.of(context).pop(unlocked);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: Icon(Icons.close, color: colors.onBackgroundFaint),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _FeaturePageView(page: _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? colors.accent
                              : colors.surfaceBorder,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _next,
                      child: Text(_isLastPage ? 'See Pro plans' : 'Continue'),
                    ),
                  ),
                  if (!_isLastPage) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : _goToPaywall,
                      child: const Text('Skip to pricing'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePageView extends StatelessWidget {
  const _FeaturePageView({required this.page});
  final _FeaturePage page;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 40, color: colors.accent),
          ),
          const SizedBox(height: 32),
          Text(
            page.headline,
            textAlign: TextAlign.center,
            style: AppTheme.handwritten(size: 26, color: colors.onBackground),
          ),
          const SizedBox(height: 14),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              height: 1.5,
              color: colors.onBackgroundSoft,
            ),
          ),
        ],
      ),
    );
  }
}
