import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';
import '../widgets/heartbeat_badge.dart';
import '../widgets/language_bar.dart';

class ProjectDetailPage extends StatelessWidget {
  final Project project;

  const ProjectDetailPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final langColor = AppTheme.languageColor(project.primaryLanguage);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppTheme.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      langColor.withOpacity(0.3),
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
                              project.primaryLanguage,
                              style: AppTheme.labelSmall.copyWith(
                                color: langColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            if (project.liveUrl.isNotEmpty)
                              HeartbeatBadge(status: project.heartbeatStatus),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          project.repo,
                          style: AppTheme.displayLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          project.owner,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.primary.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────────
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
                        label: '${project.stars}',
                        subtitle: 'Stars',
                        color: AppTheme.warning,
                      ),
                      _Divider(),
                      _Stat(
                        icon: Icons.fork_right_rounded,
                        label: '${project.forks}',
                        subtitle: 'Forks',
                        color: AppTheme.textSecondary,
                      ),
                      _Divider(),
                      _Stat(
                        icon: Icons.code_rounded,
                        label: project.primaryLanguage,
                        subtitle: 'Language',
                        color: langColor,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                const SizedBox(height: 16),

                // Language bar
                if (project.languages.isNotEmpty) ...[
                  _SectionLabel('Language Breakdown'),
                  _SectionCard(
                    child: LanguageBar(languages: project.languages),
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),
                ],

                // Description
                if (project.description.isNotEmpty) ...[
                  _SectionLabel('About'),
                  _SectionCard(
                    child: Text(project.description, style: AppTheme.bodyMedium),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),
                ],

                // Tech stack
                if (project.techStack.isNotEmpty) ...[
                  _SectionLabel('Tech Stack'),
                  _SectionCard(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: project.techStack.map((t) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusChip),
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(t, style: AppTheme.labelSmall),
                        );
                      }).toList(),
                    ),
                  ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),
                ],

                // AI Summary
                _SectionLabel('Technical Deep Dive'),
                _SectionCard(
                  child: _AISummarySection(project: project),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                const SizedBox(height: 16),

                // Architecture diagram placeholder (Phase 2)
                _SectionLabel('Architecture Diagram'),
                _SectionCard(
                  child: Container(
                    height: 120,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                      border: Border.all(
                        color: AppTheme.border,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_tree_outlined,
                          color: AppTheme.textMuted,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mermaid diagram — coming in Phase 2',
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                const SizedBox(height: 16),

                // Proof of Effort placeholder (Phase 2)
                _SectionLabel('Proof of Effort'),
                _SectionCard(
                  child: Container(
                    height: 80,
                    alignment: Alignment.center,
                    child: Text(
                      'Commit heatmap & language constellation — coming in Phase 2',
                      style: AppTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _launch(
                          'https://github.com/${project.fullName}',
                        ),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('View on GitHub'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: const BorderSide(color: AppTheme.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (project.liveUrl.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _launch(project.liveUrl),
                          icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                          label: const Text('Visit Live Site'),
                        ),
                      ),
                    ],
                  ],
                ).animate().fadeIn(delay: 450.ms),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: AppTheme.titleMedium),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
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
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label,
            style: AppTheme.titleMedium.copyWith(color: color), maxLines: 1),
        Text(subtitle, style: AppTheme.bodySmall),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppTheme.border);
  }
}

class _AISummarySection extends StatelessWidget {
  final Project project;
  const _AISummarySection({required this.project});

  @override
  Widget build(BuildContext context) {
    if (project.aiStatus == 'pending') {
      return Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text('AI is analyzing this repository...', style: AppTheme.bodyMedium),
        ],
      );
    }

    if (project.aiStatus == 'failed' || project.aiSummary.isEmpty) {
      return Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppTheme.warning, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI analysis could not be completed for this repository.',
              style: AppTheme.bodyMedium,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.primaryGradient.createShader(bounds),
              child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 6),
            Text(
              'AI-Generated Analysis',
              style: AppTheme.labelSmall.copyWith(color: AppTheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(project.aiSummary, style: AppTheme.bodyMedium),
      ],
    );
  }
}
