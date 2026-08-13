import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';
import 'theme/dashed_underline.dart';

/// Bottom-nav shell wrapping the four top-level sections of the app, styled
/// per the Warm Journal design handoff: dashed underline + filled icon for
/// the active tab, muted for inactive ones.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    (icon: Icons.home_rounded, outline: Icons.home_outlined, label: 'Home'),
    (
      icon: Icons.library_music_rounded,
      outline: Icons.library_music_outlined,
      label: 'Library',
    ),
    (
      icon: Icons.timeline_rounded,
      outline: Icons.timeline_outlined,
      label: 'Journey',
    ),
    (
      icon: Icons.person_rounded,
      outline: Icons.person_outline,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                final isActive = index == navigationShell.currentIndex;
                final color = isActive ? colors.accent : colors.tabInactive;

                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? item.icon : item.outline,
                            color: color,
                            size: 24,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight:
                                  isActive ? FontWeight.w600 : FontWeight.w500,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (isActive) DashedUnderline(color: color),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
