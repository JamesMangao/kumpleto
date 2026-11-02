import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/motion.dart';
import 'core/settings.dart';
import 'screens/bundle_detail_screen.dart';
import 'screens/document_detail_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/home_screen.dart';
import 'screens/info_page.dart';
import 'screens/location_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/scaffold_with_nav.dart';
import 'screens/settings_screen.dart';

/// Builds the app router. The first-run gate redirects to /onboarding until
/// the disclaimer has been acknowledged; [AppSettings] notifies the router
/// when that changes.
///
/// The router is created once per app (see `KumpletoApp`), so the navigation
/// stack survives locale and theme changes.
GoRouter buildRouter(AppSettings settings) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: settings,
    redirect: (context, state) {
      final onOnboarding = state.matchedLocation == '/onboarding';
      if (!settings.firstRunDone && !onOnboarding) return '/onboarding';
      if (settings.firstRunDone && onOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingScreen(settings: settings),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ScaffoldWithNav(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/documents',
              builder: (context, state) => const DocumentsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => SettingsScreen(settings: settings),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/doc/:id',
        pageBuilder: (context, state) => _fadeThrough(
          state.pageKey,
          DocumentDetailScreen(documentId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/bundle/:id',
        pageBuilder: (context, state) => _fadeThrough(
          state.pageKey,
          BundleDetailScreen(bundleId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/location',
        pageBuilder: (context, state) =>
            _fadeThrough(state.pageKey, const LocationScreen()),
      ),
      GoRoute(
        path: '/about',
        pageBuilder: (context, state) =>
            _fadeThrough(state.pageKey, const InfoPage(kind: InfoKind.about)),
      ),
      GoRoute(
        path: '/disclaimer',
        pageBuilder: (context, state) => _fadeThrough(
          state.pageKey,
          const InfoPage(kind: InfoKind.disclaimer),
        ),
      ),
      GoRoute(
        path: '/privacy',
        pageBuilder: (context, state) =>
            _fadeThrough(state.pageKey, const InfoPage(kind: InfoKind.privacy)),
      ),
    ],
  );
}

/// Shared page transition: a short fade with a small upward slide.
///
/// Collapses to an instant swap when the platform asks for reduced motion.
Page<void> _fadeThrough(LocalKey key, Widget child) {
  return CustomTransitionPage<void>(
    key: key,
    transitionDuration: Motion.medium,
    reverseTransitionDuration: Motion.fast,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (Motion.reduced(context)) return child;
      final curved = CurvedAnimation(parent: animation, curve: Motion.emphasized);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
