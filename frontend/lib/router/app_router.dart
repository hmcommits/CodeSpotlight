import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/project_model.dart';
import '../pages/home_page.dart';
import '../pages/project_detail_page.dart';
import '../services/api_service.dart';

/// App-wide router.
/// Routes:
///   /              → HomePage
///   /project/:id   → ProjectDetailPage (loaded by ID for direct/shared links)
final GoRouter appRouter = GoRouter(
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/project/:id',
      builder: (context, state) {
        // If navigating programmatically, the Project object may be passed as extra
        final extra = state.extra;
        if (extra is Project) {
          return ProjectDetailPage(project: extra);
        }
        // Otherwise (direct URL visit / refresh): load by ID from API
        return _ProjectLoader(id: state.pathParameters['id']!);
      },
    ),
  ],
  errorBuilder: (context, state) => _NotFoundPage(error: state.error),
);

// ── Loader: fetches project by ID for direct URL visits ─────────────────────

class _ProjectLoader extends StatefulWidget {
  final String id;
  const _ProjectLoader({required this.id});

  @override
  State<_ProjectLoader> createState() => _ProjectLoaderState();
}

class _ProjectLoaderState extends State<_ProjectLoader> {
  Project? _project;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await ApiService.getProjectById(widget.id);
      if (mounted) setState(() => _project = p);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_outlined,
                  size: 48, color: Color(0xFF8A8A8A)),
              const SizedBox(height: 16),
              Text('Project not found',
                  style: const TextStyle(
                      color: Color(0xFFF0F0F0),
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(
                      color: Color(0xFF8A8A8A), fontSize: 13)),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('← Back to Home',
                    style: TextStyle(color: Color(0xFF6C63FF))),
              ),
            ],
          ),
        ),
      );
    }

    if (_project == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6C63FF), strokeWidth: 2,
          ),
        ),
      );
    }

    return ProjectDetailPage(project: _project!);
  }
}

// ── 404 Page ─────────────────────────────────────────────────────────────────

class _NotFoundPage extends StatelessWidget {
  final Exception? error;
  const _NotFoundPage({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('404',
                style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6C63FF))),
            const SizedBox(height: 8),
            const Text('Page not found',
                style: TextStyle(
                    color: Color(0xFFF0F0F0),
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('← Back to Home',
                  style: TextStyle(color: Color(0xFF6C63FF))),
            ),
          ],
        ),
      ),
    );
  }
}
