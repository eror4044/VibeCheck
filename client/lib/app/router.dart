import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_page.dart';
import '../features/bootstrap/bootstrap_page.dart';
import '../features/my_ideas/create_idea_page.dart';
import '../features/my_ideas/idea_detail_page.dart';
import '../features/my_ideas/my_ideas_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/profile/edit_profile_page.dart';
import '../features/profile/profile_page.dart';
import '../features/settings/settings_page.dart';
import '../features/shell/app_shell.dart';
import '../features/stats/stats_page.dart';
import '../features/swipe/swipe_page.dart';
import '../features/swipe/swipe_done_page.dart';


final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const BootstrapPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const OnboardingPage(),
          ),
          GoRoute(
            path: '/swipe',
            builder: (context, state) => const SwipePage(),
          ),
          GoRoute(
            path: '/done',
            builder: (context, state) => const SwipeDonePage(),
          ),
          GoRoute(
            path: '/my-ideas',
            builder: (context, state) => const MyIdeasPage(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateIdeaPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return IdeaDetailPage(ideaId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return CreateIdeaPage(ideaId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/stats',
            builder: (context, state) => const StatsPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => const EditProfilePage(),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Text('Navigation error: ${state.error}'),
        ),
      );
    },
  );
});
