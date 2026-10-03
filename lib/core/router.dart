import 'package:go_router/go_router.dart';

import '../presentation/create/create_screen.dart';
import '../presentation/mine/mine_screen.dart';
import '../presentation/mine/reports_screen.dart';
import '../presentation/play/play_screen.dart';
import '../presentation/play/puzzle_detail_screen.dart';
import '../presentation/play/puzzle_edit_screen.dart';
import '../presentation/shared/app_shell.dart';

GoRouter buildRouter() => GoRouter(
      initialLocation: '/play',
      routes: [
        GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
        GoRoute(
          path: '/puzzle/:id',
          builder: (_, state) =>
              PuzzleDetailScreen(puzzleId: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, state) =>
                  PuzzleEditScreen(puzzleId: state.pathParameters['id']!),
            ),
          ],
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/play', builder: (_, _) => const PlayScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/create', builder: (_, _) => const CreateScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/mine', builder: (_, _) => const MineScreen()),
            ]),
          ],
        ),
      ],
    );
