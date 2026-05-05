import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_sidebar.dart';
import '../widgets/project_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  List<Project> _projects = [];
  List<Project> _filtered = [];
  bool _loading = true;
  String? _error;
  String _selectedStack = 'All';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProjects();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() { _loading = true; _error = null; });
    try {
      final projects = await ApiService.getProjects();
      setState(() {
        _projects = projects;
        _applyFilters();
        _loading = false;
      });
      _startPendingPoll();
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _applyFilters() {
    var result = _projects;
    if (_selectedStack != 'All') {
      result = result.where((p) => p.techStack.contains(_selectedStack)).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) =>
          p.repo.toLowerCase().contains(q) ||
          p.owner.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q)).toList();
    }
    _filtered = result;
  }

  void _startPendingPoll() {
    _pollTimer?.cancel();
    final hasPending = _projects.any((p) => p.aiStatus == 'pending');
    if (!hasPending) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final updated = await ApiService.getProjects().catchError((_) => _projects);
      if (!mounted) return;
      setState(() {
        _projects = updated;
        _applyFilters();
      });
      if (!updated.any((p) => p.aiStatus == 'pending')) _pollTimer?.cancel();
    });
  }

  List<String> get _stacks {
    final all = _projects.expand((p) => p.techStack).toSet().toList()..sort();
    return ['All', ...all];
  }

  void _openDetail(Project p) => context.go('/app/project/${p.id}', extra: p);

  void _openAddSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddRepoSheet(),
    );
    _loadProjects();
  }

  Future<void> _logout() async {
    final auth = AuthService.instance;
    if (auth.isDemo) {
      await auth.exitDemo(ApiService.baseUrl);
    } else {
      await auth.logout();
    }
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final isWide = MediaQuery.of(context).size.width > 900;
    final mainContent = CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            expandedHeight: 160,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.06),
                      AppTheme.secondary.withValues(alpha: 0.03),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Row(children: [
                        // Logo
                        ShaderMask(
                          shaderCallback: (b) =>
                              AppTheme.primaryGradient.createShader(b),
                          child: Text('CodeSpotlight',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                        const Spacer(),
                        // Demo badge or user chip
                        if (auth.isDemo)
                          _DemoBadge(onExit: _logout)
                        else if (auth.user != null)
                          _UserChip(user: auth.user!, onLogout: _logout),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.isDemo
                                ? 'Demo Portfolio'
                                : auth.user?.name.isNotEmpty == true
                                    ? '${auth.user!.name}\'s Portfolio'
                                    : 'My Portfolio',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.5),
                          ),
                          Text(
                            '${_projects.length} repositor${_projects.length == 1 ? 'y' : 'ies'} analyzed',
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: AppTheme.border),
            ),
          ),

          // ── Search ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) {
                  setState(() { _searchQuery = v; _applyFilters(); });
                },
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search repositories…',
                  prefixIcon: const Icon(Icons.search, size: 18,
                      color: AppTheme.textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16,
                              color: AppTheme.textMuted),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() { _searchQuery = ''; _applyFilters(); });
                          })
                      : null,
                ),
              ),
            ),
          ),

          // ── Stack filter chips ────────────────────────────────────────────
          if (_stacks.length > 1)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  itemCount: _stacks.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final s = _stacks[i];
                    final sel = s == _selectedStack;
                    return FilterChip(
                      label: Text(s),
                      selected: sel,
                      onSelected: (_) {
                        setState(() {
                          _selectedStack = s;
                          _applyFilters();
                        });
                      },
                      selectedColor: AppTheme.primary.withValues(alpha: 0.25),
                      backgroundColor: AppTheme.surface,
                      checkmarkColor: AppTheme.primary,
                      labelStyle: AppTheme.labelSmall.copyWith(
                          color: sel
                              ? AppTheme.primary
                              : AppTheme.textSecondary),
                      side: BorderSide(
                          color: sel ? AppTheme.primary : AppTheme.border),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusChip)),
                    );
                  },
                ),
              ),
            ),

          // ── Body ─────────────────────────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary)),
            )
          else if (_error != null)
            SliverFillRemaining(child: _ErrorState(error: _error!,
                onRetry: _loadProjects))
          else if (_filtered.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(
                hasFilter: _selectedStack != 'All' || _searchQuery.isNotEmpty,
                onAdd: _openAddSheet,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              sliver: SliverGrid(
                key: ValueKey('$_selectedStack|$_searchQuery'),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final p = _filtered[i];
                    return ProjectCard(
                      project: p,
                      onTap: () => _openDetail(p),
                    )
                        .animate(delay: (i * 45).ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.1, curve: Curves.easeOut);
                  },
                  childCount: _filtered.length,
                ),
                gridDelegate: _gridDelegate(context),
              ),
            ),
        ],
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileSidebar(
                  projects: _projects,
                  user: auth.user,
                  isDemo: auth.isDemo,
                ),
                Expanded(child: mainContent),
              ],
            )
          : mainContent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Add Repo',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        elevation: 4,
      ),
    );
  }

  SliverGridDelegate _gridDelegate(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w > 1200 ? 3 : w > 700 ? 2 : 1;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: cols,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.4,
    );
  }
}

// ── Demo badge ────────────────────────────────────────────────────────────────
class _DemoBadge extends StatelessWidget {
  final VoidCallback onExit;
  const _DemoBadge({required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.science_outlined, size: 13,
            color: AppTheme.secondary),
        const SizedBox(width: 6),
        Text('Demo Mode',
            style: AppTheme.labelSmall.copyWith(color: AppTheme.secondary)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onExit,
          child: Icon(Icons.close, size: 13,
              color: AppTheme.secondary.withValues(alpha: 0.7)),
        ),
      ]),
    );
  }
}

// ── User chip ─────────────────────────────────────────────────────────────────
class _UserChip extends StatelessWidget {
  final dynamic user; // AppUser
  final VoidCallback onLogout;
  const _UserChip({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (v) { if (v == 'logout') onLogout(); },
      color: AppTheme.surfaceHigh,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.border)),
      itemBuilder: (_) => [
        PopupMenuItem(value: 'email',
            enabled: false,
            child: Text(user.email,
                style: AppTheme.bodySmall)),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'logout',
            child: Row(children: [
              const Icon(Icons.logout, size: 14, color: AppTheme.accent),
              const SizedBox(width: 8),
              Text('Sign Out',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.accent)),
            ])),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: AppTheme.primary,
            child: Text(user.initial,
                style: const TextStyle(fontSize: 10,
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Text(user.name.isNotEmpty ? user.name : user.email.split('@').first,
              style: AppTheme.labelSmall.copyWith(color: AppTheme.textPrimary)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 14,
              color: AppTheme.textMuted),
        ]),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onAdd;
  const _EmptyState({required this.hasFilter, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.border),
          ),
          child: Icon(
            hasFilter ? Icons.search_off_rounded : Icons.code_rounded,
            size: 40, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 20),
        Text(
          hasFilter ? 'No matches' : 'No repositories yet',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 20, fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          hasFilter
              ? 'Try a different search or filter'
              : 'Add your first GitHub repo to get started',
          style: AppTheme.bodyMedium,
        ),
        if (!hasFilter) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Repository'),
          ),
        ],
      ]),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.textMuted),
        const SizedBox(height: 16),
        Text('Could not load projects', style: AppTheme.titleMedium),
        const SizedBox(height: 8),
        Text(error, style: AppTheme.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    );
  }
}

// ── Add Repo Bottom Sheet ─────────────────────────────────────────────────────
class _AddRepoSheet extends StatefulWidget {
  const _AddRepoSheet();
  @override
  State<_AddRepoSheet> createState() => _AddRepoSheetState();
}

class _AddRepoSheetState extends State<_AddRepoSheet> {
  final _formKey     = GlobalKey<FormState>();
  final _urlCtrl     = TextEditingController();
  final _liveCtrl    = TextEditingController();
  final _videoCtrl   = TextEditingController();
  bool _loading      = false;
  String? _error;

  @override
  void dispose() {
    _urlCtrl.dispose(); _liveCtrl.dispose(); _videoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService.submitProject(
          _urlCtrl.text.trim(),
          liveUrl: _liveCtrl.text.trim(),
          videoUrl: _videoCtrl.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Add Repository',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text('Gemini AI will analyze your codebase',
              style: AppTheme.bodySmall),
          const SizedBox(height: 24),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: Text(_error!,
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.error)),
            ),
            const SizedBox(height: 16),
          ],

          TextFormField(
            controller: _urlCtrl,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'GitHub Repository URL *',
              hintText: 'https://github.com/owner/repo',
              prefixIcon: Icon(Icons.link_rounded, size: 18),
            ),
            validator: (v) => (v?.contains('github.com') ?? false)
                ? null : 'Enter a valid GitHub URL',
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _liveCtrl,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Live URL (optional)',
              hintText: 'https://your-app.vercel.app',
              prefixIcon: Icon(Icons.public_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _videoCtrl,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Demo Video URL (optional)',
              hintText: 'YouTube, Loom, or direct .mp4',
              prefixIcon: Icon(Icons.play_circle_outline_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Analyze with AI',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}
