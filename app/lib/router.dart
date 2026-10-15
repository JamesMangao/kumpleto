import 'package:go_router/go_router.dart';

import 'core/settings.dart';
import 'screens/bundle_detail_screen.dart';
import 'screens/document_detail_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/scaffold_with_nav.dart';
import 'screens/settings_screen.dart';

/// Builds the app router. The first-run gate redirects to /onboarding until
/// the disclaimer has been acknowledged; [AppSettings] notifies the router
/// when that changes.
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
              builder: (context, state) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/doc/:id',
        builder: (context, state) =>
            DocumentDetailScreen(documentId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/bundle/:id',
        builder: (context, state) =>
            BundleDetailScreen(bundleId: state.pathParameters['id'] ?? ''),
      ),
    ],
  );
}
