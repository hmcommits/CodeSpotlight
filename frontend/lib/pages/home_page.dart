import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/project_card.dart';
import '../widgets/tech_filter_chips.dart';
import 'add_project_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Project> _projects = [];
  List<Project> _filtered = [];
  bool _loading = true;
  String? _error;
  String _selectedStack = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  // Polls every 5s for any cards still showing aiStatus == 'pending'
  Timer? _pendingPollTimer;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pendingPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final projects = await ApiService.getProjects();
      setState(() {
        _projects = projects;
        _applyFilters();
        _loading = false;
      });
      _schedulePendingPoll();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  /// Start a timer if any projects are still pending AI analysis.
  void _schedulePendingPoll() {
    _pendingPollTimer?.cancel();
    final hasPending = _projects.any((p) => p.aiStatus == 'pending');
    if (!hasPending) return;

    _pendingPollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final pending = _projects.where((p) => p.aiStatus == 'pending').toList();
      if (pending.isEmpty) {
        _pendingPollTimer?.cancel();
        return;
      }

      bool anyUpdated = false;
      for (final p in pending) {
        try {
          final data = await ApiService.pollAiStatus(p.id);
          final newStatus = data['aiStatus'] as String? ?? 'pending';
          if (newStatus != 'pending') {
            final idx = _projects.indexWhere((x) => x.id == p.id);
            if (idx != -1) {
              _projects[idx] = _projects[idx].copyWith(
                aiStatus: newStatus,
                aiSummary: data['aiSummary'] as String? ?? '',
                mermaidDiagram: data['mermaidDiagram'] as String? ?? '',
              );
              anyUpdated = true;
            }
          }
        } catch (_) {
          // ignore poll errors
        }
      }

      if (anyUpdated && mounted) {
        setState(() => _applyFilters());
      }

      // Stop timer if no more pending
      if (_projects.every((p) => p.aiStatus != 'pending')) {
        _pendingPollTimer?.cancel();
      }
    });
  }

  void _applyFilters() {
    _filtered = _projects.where((p) {
      final matchStack =
          _selectedStack == 'All' || p.techStack.contains(_selectedStack);
      final matchSearch = _searchQuery.isEmpty ||
          p.repo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.owner.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchStack && matchSearch;
    }).toList();
  }

  void _onStackSelected(String stack) {
    setState(() {
      _selectedStack = stack;
      _applyFilters();
    });
  }

  void _onSearch(String q) {
    setState(() {
      _searchQuery = q;
      _applyFilters();
    });
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddProjectSheet(
        onProjectAdded: (project) {
          setState(() {
            _projects.insert(0, project);
            _applyFilters();
          });
          // Immediately start polling for the new project
          _schedulePendingPoll();
        },
      ),
    );
  }

  void _openDetail(Project project) {
    context.go('/project/${project.id}', extra: project);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _loadProjects,
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              floating: true,
              backgroundColor: AppTheme.background,
              title: ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGradient.createShader(bounds),
                child: const Text(
                  'CodeSpotlight',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: _openAddSheet,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Add Repo'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    style:
                        AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search repos, owners, descriptions...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                _onSearch('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),

            // ── Filter Chips ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: TechFilterChips(
                  selected: _selectedStack,
                  onSelected: _onStackSelected,
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────────────────────
            if (_loading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const LoadingBentoCard(),
                    childCount: 6,
                  ),
                  gridDelegate: _gridDelegate(context),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                  child: _ErrorState(error: _error!, onRetry: _loadProjects))
            else if (_filtered.isEmpty)
              SliverFillRemaining(
                  child: _EmptyState(
                      hasFilter:
                          _selectedStack != 'All' || _searchQuery.isNotEmpty))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final project = _filtered[i];
                      return ProjectCard(
                        project: project,
                        onTap: () => _openDetail(project),
                      )
                          .animate(delay: (i * 50).ms)
                          .fadeIn()
                          .slideY(begin: 0.15, curve: Curves.easeOut);
                    },
                    childCount: _filtered.length,
                  ),
                  gridDelegate: _gridDelegate(context),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Repo'),
      ),
    );
  }

  SliverGridDelegate _gridDelegate(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columns = width > 1200 ? 3 : width > 700 ? 2 : 1;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.4,
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilter ? Icons.filter_list_off : Icons.folder_open_outlined,
            size: 56,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'No projects match this filter' : 'No projects yet',
            style: AppTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter
                ? 'Try selecting a different tech stack or clearing the search.'
                : 'Tap "Add Repo" to showcase your first GitHub repository.',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 56, color: AppTheme.error),
          const SizedBox(height: 16),
          Text('Could not load projects', style: AppTheme.titleMedium),
          const SizedBox(height: 8),
          Text(error, style: AppTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
