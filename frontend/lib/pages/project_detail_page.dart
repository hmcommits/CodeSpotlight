import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_analysis_card.dart';
import '../widgets/commit_heatmap.dart';
import '../widgets/heartbeat_badge.dart';
import '../widgets/language_bar.dart';
import '../widgets/language_constellation.dart';
import '../widgets/linkedin_post_sheet.dart';
import '../widgets/mermaid_diagram_view.dart';
import '../widgets/video_player_view.dart';

class ProjectDetailPage extends StatefulWidget {
  final Project? project;     // passed when navigating from the list
  final String? projectId;   // used for deep-link direct URL entry

  const ProjectDetailPage({super.key, this.project, this.projectId})
      : assert(project != null || projectId != null,
            'Provide either project or projectId');

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  Project? _project;
  bool _loadingProject = false;
  Timer? _pollTimer;
  List<List<int>> _commitData = [];
  bool _regenerating = false;

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      _project = widget.project;
      if (_project!.aiStatus == 'pending') _startPolling();
      _loadCommitActivity();
    } else {
      _fetchProject();
    }
  }

  Future<void> _fetchProject() async {
    setState(() => _loadingProject = true);
    try {
      final p = await ApiService.getProjectById(widget.projectId!);
      if (mounted) {
        setState(() { _project = p; _loadingProject = false; });
        if (p.aiStatus == 'pending') _startPolling();
        _loadCommitActivity();
      }
    } catch (e) {
      if (mounted) setState(() => _loadingProject = false);
    }
  }

  Future<void> _loadCommitActivity() async {
    try {
      final data = await ApiService.getCommitActivity(_project!.id);
      if (mounted && data.isNotEmpty) {
        setState(() => _commitData = data);
      } else if (mounted) {
        setState(() => _commitData = generateDemoHeatmapData());
      }
    } catch (_) {
      if (mounted) setState(() => _commitData = generateDemoHeatmapData());
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      try {
        final data = await ApiService.pollAiStatus(_project!.id);
        final status = data['aiStatus'] as String? ?? 'pending';
        if (status != 'pending') {
          _pollTimer?.cancel();
          if (mounted) {
            setState(() {
              _project = _project!.copyWith(
                aiStatus: status,
                aiSummary: data['aiSummary'] as String? ?? '',
                mermaidDiagram: data['mermaidDiagram'] as String? ?? '',
              );
            });
          }
        }
      } catch (_) {
        // Silently ignore poll errors Ã¢â‚¬â€ just keep trying
      }
    });
  }

  Future<void> _reanalyze() async {
    try {
      await ApiService.reanalyze(_project!.id);
      setState(() {
        _project = _project!.copyWith(aiStatus: 'pending');
      });
      _startPolling();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Re-analysis failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading spinner while fetching via deep link
    if (_project == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }
    final langColor = AppTheme.languageColor(_project!.primaryLanguage);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Ã¢â€â‚¬Ã¢â€â‚¬ App Bar Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppTheme.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  if (AuthService.instance.isAuthenticated) {
                    context.go('/app');
                  } else {
                    context.go('/discover');
                  }
                }
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 20),
                tooltip: 'Copy link',
                onPressed: () => _shareProject(context),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'project-card-${_project!.id}',
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        langColor.withValues(alpha: 0.3),
                        AppTheme.background,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: langColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _project!.primaryLanguage,
                                style: AppTheme.labelSmall.copyWith(
                                  color: langColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              if (_project!.liveUrl.isNotEmpty)
                                HeartbeatBadge(status: _project!.heartbeatStatus),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _project!.repo,
                            style: AppTheme.displayLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _project!.owner,
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.primary.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Ã¢â€â‚¬Ã¢â€â‚¬ Content Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats row
                _SectionCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Stat(
                        icon: Icons.star_rounded,
                        label: '${_project!.stars}',
                        subtitle: 'Stars',
                        color: AppTheme.warning,
                      ),
                      _VerticalDivider(),
                      _Stat(
                        icon: Icons.fork_right_rounded,
                        label: '${_project!.forks}',
                        subtitle: 'Forks',
                        color: AppTheme.secondary,
                      ),
                      _VerticalDivider(),
                      _Stat(
                        icon: Icons.code_rounded,
                        label: _project!.primaryLanguage,
                        subtitle: 'Language',
                        color: langColor,
                      ),
                      if (_project!.topics.isNotEmpty) ...[
                        _VerticalDivider(),
                        _Stat(
                          icon: Icons.label_rounded,
                          label: '${_project!.topics.length}',
                          subtitle: 'Topics',
                          color: AppTheme.primary,
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                const SizedBox(height: 16),

                // Language bar
                if (_project!.languages.isNotEmpty) ...[
                  _SectionLabel('Language Breakdown', icon: Icons.pie_chart_outline_rounded),
                  _SectionCard(
                    child: LanguageBar(languages: _project!.languages),
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),
                ],

                // Description
                if (_project!.description.isNotEmpty) ...[
                  _SectionLabel('About', icon: Icons.info_outline_rounded),
                  _SectionCard(
                    child: Text(_project!.description, style: AppTheme.bodyMedium),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),
                ],

                // Demo Video (YouTube / Loom / direct MP4)
                if (_project!.videoUrl.isNotEmpty) ...[
                  _SectionLabel('Demo Video', icon: Icons.play_circle_outline_rounded),
                  _SectionCard(
                    child: VideoPlayerView(videoUrl: _project!.videoUrl),
                  ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),
                ],

                // Tech stack
                if (_project!.techStack.isNotEmpty) ...[
                  _SectionLabel('Tech Stack', icon: Icons.layers_rounded),
                  _SectionCard(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _project!.techStack.map((t) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusChip),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(t, style: AppTheme.labelSmall),
                        );
                      }).toList(),
                    ),
                  ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),
                ],

                // AI Summary Ã¢â‚¬â€ live polling
                _SectionLabel('Technical Deep Dive', icon: Icons.auto_awesome_rounded),
                _SectionCard(
                  child: _buildAiSection(),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                const SizedBox(height: 16),

                // Architecture Diagram Ã¢â‚¬â€ Mermaid.js
                Row(
                  children: [
                    Expanded(child: _SectionLabel('Architecture Diagram', icon: Icons.account_tree_outlined)),
                    if (_project!.aiStatus == 'done')
                      TextButton.icon(
                        onPressed: _regenerating ? null : _regenDiagram,
                        icon: _regenerating
                            ? const SizedBox(
                                width: 12, height: 12,
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5, color: AppTheme.primary))
                            : const Icon(Icons.refresh, size: 14),
                        label: Text(_regenerating ? 'RegeneratingÃ¢â‚¬Â¦' : 'Regenerate'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          textStyle: const TextStyle(fontSize: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                        ),
                      ),
                  ],
                ),
                _SectionCard(
                  child: _project!.mermaidDiagram.isNotEmpty
                      ? MermaidDiagramView(diagram: _project!.mermaidDiagram)
                      : Container(
                          height: 90,
                          alignment: Alignment.center,
                          child: Text(
                            _project!.aiStatus == 'pending'
                                ? 'Diagram will appear after AI analysis completes.'
                                : 'No architecture diagram available.',
                            style: AppTheme.bodySmall,
                          ),
                        ),
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                const SizedBox(height: 16),

                // Language Constellation
                _SectionLabel('Language Constellation', icon: Icons.bubble_chart_rounded),
                _SectionCard(
                  child: _project!.languages.isNotEmpty
                      ? LanguageConstellation(languages: _project!.languages)
                      : Center(
                          child: Text('No language data.',
                              style: AppTheme.bodySmall),
                        ),
                ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.1),
                const SizedBox(height: 16),

                // Commit Heatmap Ã¢â‚¬â€ Proof of Effort
                _SectionLabel('Proof of Effort', icon: Icons.local_fire_department_rounded),
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.local_fire_department_rounded,
                            size: 14, color: AppTheme.primary),
                        const SizedBox(width: 5),
                        Text('Commit Activity Ã¢â‚¬â€ past 12 months',
                            style: AppTheme.labelSmall
                                .copyWith(color: AppTheme.primary)),
                      ]),
                      const SizedBox(height: 12),
                      CommitHeatmap(
                        weeklyData: _commitData.isNotEmpty
                            ? _commitData
                            : generateDemoHeatmapData(),
                        accentColor: AppTheme.languageColor(
                            _project!.primaryLanguage),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _DetailActionButton(
                        icon: Icons.code_rounded,
                        label: 'View on GitHub',
                        onTap: () => _launch(
                            'https://github.com/${_project!.fullName}'),
                        outlined: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DetailActionButton(
                        icon: Icons.share_rounded,
                        label: 'LinkedIn Post',
                        color: const Color(0xFF0A66C2),
                        onTap: () => showLinkedInPostSheet(
                            context, _project!),
                      ),
                    ),
                    if (_project!.liveUrl.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DetailActionButton(
                          icon: Icons.rocket_launch_rounded,
                          label: 'Live Site',
                          onTap: () => _launch(_project!.liveUrl),
                        ),
                      ),
                    ],
                  ],
                ).animate().fadeIn(delay: 450.ms),

                const SizedBox(height: 16),

                // ── Management buttons (owner only) ────────────────────────
                if (AuthService.instance.user?.id == _project!.userId)
                  Row(
                    children: [
                      Expanded(
                        child: _ManageBtn(
                          icon: Icons.auto_awesome_rounded,
                          label: 'Generate README',
                          color: AppTheme.accent,
                          onTap: _showReadmeModal,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ManageBtn(
                          icon: Icons.edit_rounded,
                          label: 'Edit',
                          color: AppTheme.primary,
                          onTap: _editProject,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _ManageBtn(
                        icon: Icons.delete_outline_rounded,
                        label: '',
                        color: AppTheme.error,
                        onTap: _deleteProject,
                        iconOnly: true,
                      ),
                    ],
                  ).animate().fadeIn(delay: 480.ms),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSection() {
    if (_project!.aiStatus == 'pending') {
      return const AiAnalysisPending();
    }
    if (_project!.aiStatus == 'failed' || _project!.aiSummary.isEmpty) {
      return AiAnalysisFailed(onRetry: _reanalyze);
    }
    return AiAnalysisCard(aiSummary: _project!.aiSummary);
  }

  void _shareProject(BuildContext context) {
    // Build the shareable URL based on the current browser origin
    final origin =
        Uri.base.scheme == 'http' || Uri.base.scheme == 'https'
            ? '${Uri.base.scheme}://${Uri.base.host}'
                '${Uri.base.hasPort ? ':${Uri.base.port}' : ''}'
            : 'https://codespotlight.web.app';
    final url = '$origin/project/${_project!.id}';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline,
              size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Link copied: $url',
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
        backgroundColor: const Color(0xFF1E1E1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Delete project ────────────────────────────────────────────────────────
  Future<void> _deleteProject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Delete Project', style: AppTheme.titleMedium),
        content: Text(
          'Are you sure you want to remove "${_project!.repo}" from your portfolio? This cannot be undone.',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ApiService.deleteProject(_project!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/app');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  // ── Edit project (liveUrl + videoUrl) ─────────────────────────────────────
  Future<void> _editProject() async {
    final liveCtrl  = TextEditingController(text: _project!.liveUrl);
    final videoCtrl = TextEditingController(text: _project!.videoUrl);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Edit Project', style: AppTheme.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: liveCtrl,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Live URL',
                prefixIcon: Icon(Icons.public_rounded, size: 16),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: videoCtrl,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Demo Video URL',
                prefixIcon: Icon(Icons.play_circle_outline, size: 16),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    liveCtrl.dispose();
    videoCtrl.dispose();
    if (saved != true || !mounted) return;
    try {
      final updated = await ApiService.editProject(
        _project!.id,
        liveUrl:  liveCtrl.text.trim(),
        videoUrl: videoCtrl.text.trim(),
      );
      if (mounted) setState(() => _project = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  // ── AI README modal ───────────────────────────────────────────────────────
  Future<void> _showReadmeModal() async {
    String? readme;
    bool loading = true;
    String? err;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          if (loading) {
            ApiService.generateReadme(_project!.id).then((r) {
              if (ctx.mounted) setS(() { readme = r; loading = false; });
            }).catchError((e) {
              if (ctx.mounted) setS(() { err = e.toString(); loading = false; });
            });
          }
          return DefaultTabController(
            length: 2,
            child: DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, ctrl) => Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            color: AppTheme.accent, size: 20),
                        const SizedBox(width: 10),
                        Text('AI-Generated README',
                            style: AppTheme.titleMedium),
                        const Spacer(),
                        if (readme != null)
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            tooltip: 'Copy README',
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: readme!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('README copied to clipboard!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  if (readme != null && !loading && err == null)
                    const TabBar(
                      indicatorColor: AppTheme.primary,
                      labelColor: AppTheme.primary,
                      unselectedLabelColor: AppTheme.textSecondary,
                      tabs: [
                        Tab(text: 'Preview'),
                        Tab(text: 'Code'),
                      ],
                    ),
                  if (readme == null || loading || err != null)
                    const Divider(height: 1),
                  Expanded(
                    child: loading
                        ? const Center(
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              CircularProgressIndicator(color: AppTheme.primary),
                              SizedBox(height: 16),
                              Text('Generating README with Gemini AI...'),
                            ]),
                          )
                        : err != null
                            ? Center(child: Text('Error: $err',
                                style: AppTheme.bodySmall))
                            : TabBarView(
                                children: [
                                  // Preview Tab
                                  Markdown(
                                    controller: ctrl,
                                    data: readme ?? '',
                                    selectable: true,
                                    styleSheet: MarkdownStyleSheet(
                                      p: AppTheme.bodyMedium,
                                      h1: AppTheme.displayLarge,
                                      h2: AppTheme.titleLarge,
                                      h3: AppTheme.titleMedium,
                                      code: GoogleFonts.firaCode(
                                          fontSize: 13,
                                          backgroundColor: AppTheme.surfaceHigh,
                                          color: AppTheme.textPrimary),
                                      codeblockDecoration: BoxDecoration(
                                        color: AppTheme.surfaceHigh,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onTapLink: (text, href, title) {
                                      if (href != null) _launch(href);
                                    },
                                  ),
                                  // Code Tab
                                  SingleChildScrollView(
                                    controller: ctrl,
                                    padding: const EdgeInsets.all(20),
                                    child: SelectableText(
                                      readme ?? '',
                                      style: GoogleFonts.firaCode(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                          height: 1.6),
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Triggers a full re-analysis (new Gemini call) and polls until done.
  Future<void> _regenDiagram() async {
    if (_regenerating) return;
    setState(() => _regenerating = true);
    try {
      await ApiService.reanalyze(_project!.id);
      // Poll until aiStatus != 'pending'
      for (var i = 0; i < 30; i++) {
        await Future.delayed(const Duration(seconds: 4));
        final status = await ApiService.pollAiStatus(_project!.id);
        if (status['aiStatus'] != 'pending') {
          final updated = _project!.copyWith(
            aiStatus: status['aiStatus'] as String?,
            aiSummary: status['aiSummary'] as String?,
            mermaidDiagram: status['mermaidDiagram'] as String?,
          );
          if (mounted) setState(() => _project = updated);
          break;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _regenerating = false);
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Helper widgets Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _SectionLabel(this.label, {this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: AppTheme.primary),
          const SizedBox(width: 8),
        ],
        Text(label,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.2)),
      ]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;

  const _Stat({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        Text(subtitle,
            style: AppTheme.bodySmall.copyWith(fontSize: 11)),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppTheme.border);
  }
}

// ── Manage Button ───────────────────────────────────────────────────────────────
class _ManageBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool iconOnly;

  const _ManageBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.iconOnly = false,
  });

  @override
  State<_ManageBtn> createState() => _ManageBtnState();
}

class _ManageBtnState extends State<_ManageBtn> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            vertical: 14,
            horizontal: widget.iconOnly ? 14 : 0,
          ),
          decoration: BoxDecoration(
            color: _hov ? widget.color.withValues(alpha: 0.12) : widget.color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hov ? widget.color.withValues(alpha: 0.5) : widget.color.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 16, color: widget.color),
              if (!widget.iconOnly) ...[
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Detail page action button ─────────────────────────────────────────────────
class _DetailActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;
  final Color? color;
  const _DetailActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.outlined = false,
    this.color,
  });

  @override
  State<_DetailActionButton> createState() => _DetailActionButtonState();
}

class _DetailActionButtonState extends State<_DetailActionButton> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? AppTheme.primary;
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: widget.outlined ? null
                : LinearGradient(colors: [c, c.withValues(alpha: 0.75)]),
            color: widget.outlined
                ? (_hov ? c.withValues(alpha: 0.08) : Colors.transparent)
                : null,
            borderRadius: BorderRadius.circular(12),
            border: widget.outlined
                ? Border.all(color: _hov ? c : AppTheme.border, width: 1.5)
                : null,
            boxShadow: !widget.outlined && _hov
                ? [BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 16)]
                : [],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(widget.icon, size: 15,
                color: widget.outlined
                    ? (_hov ? c : AppTheme.textSecondary)
                    : Colors.white),
            const SizedBox(width: 7),
            Text(widget.label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.outlined
                        ? (_hov ? c : AppTheme.textSecondary)
                        : Colors.white)),
          ]),
        ),
      ),
    );
  }
}

