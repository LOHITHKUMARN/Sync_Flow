import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/projects/presentation/project_list_screen.dart';
import '../../features/projects/presentation/project_providers.dart';
import '../../features/settings/presentation/edit_profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/sync/presentation/activity_screen.dart';
import '../../features/tasks/presentation/kanban_board_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      if (state.matchedLocation == '/splash') {
        return null;
      }

      final isAuthRoute = state.matchedLocation == '/welcome' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // If user is already logged in and on an auth screen, take them straight to projects
      if (currentUser != null && isAuthRoute) {
        return '/projects';
      }

      // If user is not logged in and tries to access authenticated screens, send to welcome
      if (currentUser == null && !isAuthRoute) {
        return '/welcome';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/projects',
        builder: (context, state) => const ProjectListScreen(),
        routes: [
          GoRoute(
            path: ':id/kanban',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return KanbanBoardScreen(projectId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/board',
        redirect: (context, state) {
          final activeProject = ref.read(activeProjectProvider);
          final projects = ref.read(projectsNotifierProvider).value ?? [];
          if (activeProject != null) {
            return '/projects/${activeProject.id}/kanban';
          } else if (projects.isNotEmpty) {
            ref.read(activeProjectProvider.notifier).setProject(projects.first);
            return '/projects/${projects.first.id}/kanban';
          }
          return '/projects';
        },
      ),
      GoRoute(
        path: '/activity',
        builder: (context, state) => const ActivityScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
