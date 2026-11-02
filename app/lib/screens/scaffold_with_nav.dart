import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/shared.dart';

/// Bottom-navigation shell: Home / Documents / Settings with modern design.
class ScaffoldWithNav extends StatelessWidget {
  const ScaffoldWithNav({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: shell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          height: 68,
          backgroundColor: Colors.transparent,
          indicatorColor: isDark ? const Color(0xFF1E352B) : const Color(0xFFD4ECE3),
          onDestinationSelected: (index) => shell.goBranch(
            index,
            initialLocation: index == shell.currentIndex,
          ),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l10n.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.description_outlined),
              selectedIcon: const Icon(Icons.description),
              label: l10n.navDocuments,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: l10n.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable AppBar with the Kumpleto brand icon and mandatory "Unofficial" indicator.
AppBar unofficialAppBar(
  BuildContext context,
  String title, {
  IconData? leadingIcon,
  Widget? leadingWidget,
}) {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return AppBar(
    titleSpacing: 16,
    title: Row(
      children: [
        leadingWidget ??
            (leadingIcon != null
                ? SquircleIcon(icon: leadingIcon, size: 32, iconSize: 18)
                : const KumpletoLogo(size: 30, radius: 8)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          container: true,
          label: l10n.unofficialBadge,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF23352C) : const Color(0xFFE2EFE9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.unofficialBadge,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF8CE0C4) : AppTheme.primaryTeal,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
