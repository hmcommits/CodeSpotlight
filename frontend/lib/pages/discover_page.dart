import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/project_card.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  List<Project> _projects = [];
  int _total = 0;
  bool _loading = true;
  String? _error;

  String _sort = 'newest';
  String _stack = '';
  final _searchCtrl = TextEditingController();

  static const _sortOptions = [
    ('newest', 'Newest', Icons.schedule_rounded),
    ('stars', 'Most Stars', Icons.star_rounded),
    ('forks', 'Most Forks', Icons.fork_right_rounded),
  ];

  static const _stackOptions = [
    '', 'React', 'Flutter', 'Node.js', 'AI/ML', 'MongoDB',
    'TypeScript', 'Python', 'Web3', 'Go', 'Rust',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getPublicFeed(
        stack: _stack.isEmpty ? null : _stack,
        sort: _sort,
      );
      if (mounted) {
        setState(() {
          _projects = data['projects'] as List<Project>;
          _total    = data['total'] as int;
          _loading  = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            expandedHeight: 160,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () =>
                  auth.isAuthenticated ? context.go('/app') : context.go('/'),
            ),
            actions: [
              if (auth.isAuthenticated)
                TextButton.icon(
                  onPressed: () => context.go('/app'),
                  icon: const Icon(Icons.dashboard_rounded, size: 15),
                  label: const Text('My Portfolio'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary),
                ),
              if (!auth.isAuthenticated)
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Sign In'),
                ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(24, 72, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(children: [
                      ShaderMask(
                        shaderCallback: (b) =>
                            AppTheme.primaryGradient.createShader(b),
                        child: Text('Discover',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            )),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('$_total projects',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    Text('Explore developer portfolios',
                        style: AppTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ),

          // ── Filters ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(children: [
              // Sort chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: _sortOptions.map((opt) {
                    final (val, label, icon) = opt;
                    final sel = _sort == val;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: Icon(icon, size: 13),
                        label: Text(label),
                        selected: sel,
                        onSelected: (_) => setState(() {
                          _sort = val;
                          _load();
                        }),
                        selectedColor:
                            AppTheme.primary.withValues(alpha: 0.2),
                        backgroundColor: AppTheme.surface,
                        checkmarkColor: AppTheme.primary,
                        labelStyle: AppTheme.labelSmall.copyWith(
                            color: sel
                                ? AppTheme.primary
                                : AppTheme.textSecondary),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Stack filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: _stackOptions.map((s) {
                    final label = s.isEmpty ? 'All' : s;
                    final sel = _stack == s;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(label),
                        selected: sel,
                        onSelected: (_) => setState(() {
                          _stack = s;
                          _load();
                        }),
                        selectedColor:
                            AppTheme.secondary.withValues(alpha: 0.2),
                        backgroundColor: AppTheme.surface,
                        checkmarkColor: AppTheme.secondary,
                        labelStyle: AppTheme.labelSmall.copyWith(
                            color: sel
                                ? AppTheme.secondary
                                : AppTheme.textSecondary),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Divider(height: 1, color: AppTheme.border),
            ]),
          ),

          // ── Content ───────────────────────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary)),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        size: 48, color: AppTheme.textMuted),
                    const SizedBox(height: 12),
                    Text(_error!, style: AppTheme.bodyMedium),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_projects.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.explore_off_rounded,
                        size: 56, color: AppTheme.textMuted),
                    const SizedBox(height: 16),
                    Text('No projects found', style: AppTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text('Be the first to add your project!',
                        style: AppTheme.bodyMedium),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => auth.isAuthenticated
                          ? context.go('/app')
                          : context.go('/login'),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Your Project'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverGrid(
                gridDelegate: _gridDelegate(context),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final p = _projects[i];
                    return ProjectCard(
                      project: p,
                      onTap: () =>
                          context.go('/app/project/${p.id}', extra: p),
                    )
                        .animate(delay: (i * 40).ms)
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.08, curve: Curves.easeOut);
                  },
                  childCount: _projects.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  SliverGridDelegate _gridDelegate(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w > 1100 ? 3 : w > 650 ? 2 : 1;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: cols,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      mainAxisExtent: 350,
    );
  }
}
