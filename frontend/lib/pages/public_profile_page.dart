import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/project_card.dart';

class PublicProfilePage extends StatefulWidget {
  final String userId;
  const PublicProfilePage({super.key, required this.userId});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getPublicProfile(widget.userId);
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text('Portfolio', style: AppTheme.titleMedium),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/discover'),
            icon: const Icon(Icons.explore_rounded, size: 16),
            label: const Text('Discover'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : _ProfileBody(data: _data!),
    );
  }
}

// ── Profile body ──────────────────────────────────────────────────────────────
class _ProfileBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ProfileBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final user = data['user'] as Map<String, dynamic>;
    final stats = data['stats'] as Map<String, dynamic>;
    final projects = data['projects'] as List<Project>;
    final name = (user['name'] as String? ?? '').isNotEmpty
        ? user['name'] as String
        : (user['email'] as String? ?? 'Developer').split('@').first;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'D';

    return CustomScrollView(
      slivers: [
        // ── Hero header ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.12),
                  AppTheme.background,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                const SizedBox(height: 16),
                Text(
                  name,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_rounded,
                        size: 14, color: AppTheme.primary),
                    const SizedBox(width: 5),
                    Text(
                      'CodeSpotlight Portfolio',
                      style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primary),
                    ),
                  ],
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 24),

                // Stats row
                _StatsRow(stats: stats)
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.1),
              ],
            ),
          ),
        ),

        // ── Projects grid ──────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          sliver: projects.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(children: [
                        const Icon(Icons.folder_open_rounded,
                            size: 48, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        Text('No public projects yet.',
                            style: AppTheme.bodyMedium),
                      ]),
                    ),
                  ),
                )
              : SliverGrid(
                  gridDelegate: _gridDelegate(context),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final p = projects[i];
                      return ProjectCard(
                        project: p,
                        onTap: () =>
                            context.go('/app/project/${p.id}', extra: p),
                      )
                          .animate(delay: (i * 50).ms)
                          .fadeIn(duration: 350.ms)
                          .slideY(begin: 0.08);
                    },
                    childCount: projects.length,
                  ),
                ),
        ),
      ],
    );
  }

  SliverGridDelegate _gridDelegate(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w > 1100 ? 3 : w > 650 ? 2 : 1;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: cols,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.1,
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _StatPill(Icons.code_rounded, '${stats['totalRepos']}', 'Projects',
            AppTheme.primary),
        _StatPill(Icons.star_rounded, '${stats['totalStars']}', 'Stars',
            AppTheme.warning),
        _StatPill(Icons.fork_right_rounded, '${stats['totalForks']}', 'Forks',
            AppTheme.secondary),
        _StatPill(Icons.public_rounded, '${stats['liveDeployments']}', 'Live',
            AppTheme.success),
        _StatPill(Icons.auto_awesome_rounded, '${stats['aiAnalyzed']}',
            'AI Analyzed', AppTheme.accent),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _StatPill(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 7),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted)),
      ]),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_off_outlined,
              size: 56, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text('Profile not found', style: AppTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(error,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
