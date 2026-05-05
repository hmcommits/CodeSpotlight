import 'package:go_router/go_router.dart';
import '../pages/landing_page.dart';
import '../pages/auth_pages.dart';
import '../pages/home_page.dart';
import '../pages/project_detail_page.dart';
import '../pages/public_profile_page.dart';
import '../pages/discover_page.dart';
import '../services/auth_service.dart';
import '../models/project_model.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final auth = AuthService.instance;
    final isApp = state.matchedLocation.startsWith('/app');
    // Guard /app routes — must be authed or in demo mode
    if (isApp && !auth.isAuthenticated) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const LandingPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (_, __) => const RegisterPage(),
    ),
    // ── Public routes (no auth needed) ──────────────────────────────────────
    GoRoute(
      path: '/discover',
      builder: (_, __) => const DiscoverPage(),
    ),
    GoRoute(
      path: '/profile/:userId',
      builder: (_, state) => PublicProfilePage(
        userId: state.pathParameters['userId']!,
      ),
    ),
    // ── Authenticated routes ─────────────────────────────────────────────────
    GoRoute(
      path: '/app',
      builder: (_, __) => const HomePage(),
    ),
    GoRoute(
      path: '/app/project/:id',
      builder: (context, state) {
        final extra = state.extra;
        final project = extra is Project ? extra : null;
        final id = state.pathParameters['id']!;
        return ProjectDetailPage(
          project: project,
          projectId: id,
        );
      },
    ),
  ],
);
