import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:recicla_radar_sp/core/router/app_routes.dart';
import 'package:recicla_radar_sp/core/widgets/home_shell.dart';
import 'package:recicla_radar_sp/features/alerts/alert_detail_screen.dart';
import 'package:recicla_radar_sp/features/alerts/alerts_screen.dart';
import 'package:recicla_radar_sp/features/auth/forgot_password_screen.dart';
import 'package:recicla_radar_sp/features/auth/login_screen.dart';
import 'package:recicla_radar_sp/features/auth/register_screen.dart';
import 'package:recicla_radar_sp/features/bins_map/bin_detail_screen.dart';
import 'package:recicla_radar_sp/features/bins_map/bins_screen.dart';
import 'package:recicla_radar_sp/features/demand_map/demand_map_screen.dart';
import 'package:recicla_radar_sp/features/inspection/inspection_screen.dart';
import 'package:recicla_radar_sp/features/overview/overview_screen.dart';
import 'package:recicla_radar_sp/features/settings/settings_screen.dart';
import 'package:recicla_radar_sp/state/session_provider.dart';

GoRouter createAppRouter(SessionProvider session) {
  return GoRouter(
    initialLocation: AppRoutes.loginPath,
    refreshListenable: session,
    redirect: (context, state) {
      final isPublic = AppRoutes.publicPaths.contains(state.matchedLocation);
      if (!session.isLoggedIn && !isPublic) return AppRoutes.loginPath;
      if (session.isLoggedIn && isPublic) return AppRoutes.homePath;
      return null;
    },
    routes: [
      GoRoute(
        name: AppRoutes.login,
        path: AppRoutes.loginPath,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: AppRoutes.register,
        path: AppRoutes.registerPath,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        name: AppRoutes.forgotPassword,
        path: AppRoutes.forgotPasswordPath,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              name: AppRoutes.home,
              path: AppRoutes.homePath,
              builder: (context, state) => const OverviewScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              name: AppRoutes.demand,
              path: '/demanda',
              builder: (context, state) => const DemandMapScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              name: AppRoutes.bins,
              path: '/lixeiras',
              builder: (context, state) => const BinsScreen(),
              routes: [
                GoRoute(
                  name: AppRoutes.bin,
                  path: ':id',
                  builder: (context, state) =>
                      BinDetailScreen(binId: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              name: AppRoutes.alerts,
              path: '/alertas',
              builder: (context, state) => const AlertsScreen(),
              routes: [
                GoRoute(
                  name: AppRoutes.alert,
                  path: ':id',
                  builder: (context, state) =>
                      AlertDetailScreen(alertId: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(
        name: AppRoutes.inspection,
        path: '/vistoria',
        builder: (context, state) =>
            InspectionScreen(binId: state.uri.queryParameters['binId']),
      ),
      GoRoute(
        name: AppRoutes.settings,
        path: '/configuracoes',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: Center(
        child: FilledButton(
          onPressed: () => context.go(AppRoutes.homePath),
          child: const Text('Voltar ao início'),
        ),
      ),
    ),
  );
}
