import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';
import 'heartbeat_badge.dart';
import 'language_bar.dart';
import 'linkedin_post_sheet.dart';

class ProjectCard extends StatefulWidget {
  final Project project;
  final VoidCallback onTap;

  const ProjectCard({super.key, required this.project, required this.onTap});

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final langColor = AppTheme.languageColor(widget.project.primaryLanguage);
    final p = widget.project;

    return Hero(
      tag: 'project-card-${p.id}',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(
                color: _hovered
                    ? langColor.withValues(alpha: 0.5)
                    : AppTheme.border,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: langColor.withValues(alpha: 0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                        spreadRadius: -2,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            // ── Column fills the grid cell; Stack expands to fill remaining space ──
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top accent bar ──────────────────────────────────────────
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      langColor,
                      langColor.withValues(alpha: 0.3),
                    ]),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radiusCard),
                      topRight: Radius.circular(AppTheme.radiusCard),
                    ),
                  ),
                ),

                // ── Card body (expands to fill space) ──────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row: lang dot, repo name, live badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: langColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: langColor.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.repo,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    p.owner,
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.primary
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (p.liveUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child:
                                    HeartbeatBadge(status: p.heartbeatStatus),
                              ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Description
                        Flexible(
                          child: Text(
                            p.description.isNotEmpty
                                ? p.description
                                : 'No description available.',
                            style: AppTheme.bodyMedium.copyWith(fontSize: 13),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Stats + AI badge row
                        Row(
                          children: [
                            _StatChip(
                              icon: Icons.star_rounded,
                              label: _fmt(p.stars),
                              color: AppTheme.warning,
                            ),
                            const SizedBox(width: 10),
                            _StatChip(
                              icon: Icons.fork_right_rounded,
                              label: _fmt(p.forks),
                              color: AppTheme.textMuted,
                            ),
                            const Spacer(),
                            _StatusBadge(aiStatus: p.aiStatus),
                          ],
                        ),

                        // Language bar
                        if (p.languages.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: SizedBox(
                              height: 4,
                              child: LanguageBar(languages: p.languages),
                            ),
                          ),
                        ],

                        // Tech chips
                        if (p.techStack.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: p.techStack.take(3).map((t) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusChip),
                                  border: Border.all(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(t,
                                    style: AppTheme.labelSmall
                                        .copyWith(fontSize: 10)),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Action buttons (fixed height at bottom) ─────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(children: [
                    Expanded(
                      child: _CardActionBtn(
                        icon: Icons.code_rounded,
                        label: 'GitHub',
                        onTap: () async {
                          final url = Uri.parse(
                              'https://github.com/${p.fullName}');
                          if (await canLaunchUrl(url)) {
                            launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CardActionBtn(
                        icon: Icons.share_rounded,
                        label: 'LinkedIn',
                        onTap: () => showLinkedInPostSheet(context, p),
                        accent: const Color(0xFF0A66C2),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

// ── Stat chip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(label, style: AppTheme.labelSmall.copyWith(color: color)),
      ],
    );
  }
}

// ── AI status badge ───────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String aiStatus;
  const _StatusBadge({required this.aiStatus});

  @override
  Widget build(BuildContext context) {
    if (aiStatus == 'done') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 9, color: Colors.white),
            const SizedBox(width: 3),
            Text('AI',
                style: AppTheme.labelSmall.copyWith(color: Colors.white)),
          ],
        ),
      );
    }
    if (aiStatus == 'pending') {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(
            width: 8,
            height: 8,
            child: CircularProgressIndicator(
                strokeWidth: 1.5, color: AppTheme.primary)),
        const SizedBox(width: 5),
        Text('Analyzing…',
            style: AppTheme.labelSmall.copyWith(color: AppTheme.primary)),
      ]);
    }
    return const SizedBox.shrink();
  }
}

// ── Card action button ────────────────────────────────────────────────────────
class _CardActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accent;
  const _CardActionBtn(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.accent});

  @override
  State<_CardActionBtn> createState() => _CardActionBtnState();
}

class _CardActionBtnState extends State<_CardActionBtn> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.accent ?? AppTheme.textSecondary;
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: _hov ? c.withValues(alpha: 0.12) : AppTheme.surfaceHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: _hov ? c.withValues(alpha: 0.5) : AppTheme.border),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(widget.icon, size: 13, color: _hov ? c : AppTheme.textMuted),
            const SizedBox(width: 5),
            Text(widget.label,
                style: AppTheme.labelSmall.copyWith(
                    color: _hov ? c : AppTheme.textSecondary, fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}
