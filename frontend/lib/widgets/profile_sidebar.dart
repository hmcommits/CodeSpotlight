import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/project_model.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class ProfileSidebar extends StatelessWidget {
  final List<Project> projects;
  final AppUser? user;
  final bool isDemo;

  const ProfileSidebar({
    super.key,
    required this.projects,
    required this.user,
    required this.isDemo,
  });

  // â”€â”€ Computed aggregates â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Map<String, double> get _combinedLanguages {
    final totals = <String, double>{};
    for (final p in projects) {
      for (final e in p.languages.entries) {
        totals[e.key] = (totals[e.key] ?? 0) + (e.value as num).toDouble();
      }
    }
    return totals;
  }

  List<MapEntry<String, int>> get _topSkills {
    final freq = <String, int>{};
    for (final p in projects) {
      for (final t in p.techStack) {
        freq[t] = (freq[t] ?? 0) + 1;
      }
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).toList();
  }

  int get _totalStars => projects.fold(0, (s, p) => s + p.stars);
  int get _totalForks => projects.fold(0, (s, p) => s + p.forks);

  String get _topLanguage {
    final langs = _combinedLanguages;
    if (langs.isEmpty) return 'N/A';
    return langs.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  @override
  Widget build(BuildContext context) {
    final name = user?.name.isNotEmpty == true
        ? user!.name
        : isDemo
            ? 'Demo User'
            : 'Developer';
    final initial = user?.initial ?? (isDemo ? 'D' : 'U');
    final email = user?.email ?? '';

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),

            // â”€â”€ Avatar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _Avatar(initial: initial).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: 14),

            Text(
              name,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            if (email.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(email,
                    style: AppTheme.bodySmall.copyWith(fontSize: 11),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis),
              ),
            if (isDemo)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
                ),
                child: Text('Demo Mode',
                    style: AppTheme.labelSmall.copyWith(color: AppTheme.secondary)),
              ),

            const SizedBox(height: 20),

            // â”€â”€ Share Profile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (!isDemo && user != null)
              _ShareProfileButton(userId: user!.id),

            const SizedBox(height: 20),
            _Divider(),

            // â”€â”€ Stats â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            const SizedBox(height: 16),
            _SectionHeader(icon: Icons.bar_chart_rounded, label: 'Portfolio Stats'),
            const SizedBox(height: 12),
            _StatsGrid(
              repos: projects.length,
              stars: _totalStars,
              forks: _totalForks,
              lang: _topLanguage,
            ),

            const SizedBox(height: 20),
            _Divider(),

            // â”€â”€ Skills â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (_topSkills.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionHeader(icon: Icons.psychology_rounded, label: 'Top Skills'),
              const SizedBox(height: 12),
              _SkillGraph(skills: _topSkills),
              const SizedBox(height: 20),
              _Divider(),
            ],

            // â”€â”€ Language Constellation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (_combinedLanguages.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionHeader(icon: Icons.bubble_chart_rounded, label: 'Languages'),
              const SizedBox(height: 12),
              _LanguageBubbles(languages: _combinedLanguages),
              const SizedBox(height: 20),
              _Divider(),
            ],

            // â”€â”€ About section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            const SizedBox(height: 16),
            _SectionHeader(icon: Icons.info_outline_rounded, label: 'About'),
            const SizedBox(height: 12),
            _AboutSection(
              repoCount: projects.length,
              liveCount: projects.where((p) => p.liveUrl.isNotEmpty).length,
              aiDoneCount: projects.where((p) => p.aiStatus == 'done').length,
              videoCount: projects.where((p) => p.videoUrl.isNotEmpty).length,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05);
  }
}

// â”€â”€ Avatar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _Avatar extends StatelessWidget {
  final String initial;
  const _Avatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// â”€â”€ Share Profile Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ShareProfileButton extends StatelessWidget {
  final String userId;
  const _ShareProfileButton({required this.userId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final base = Uri.base.origin;
        final link = '$base/#/profile/$userId';
        Clipboard.setData(ClipboardData(text: link));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile link copied!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.link_rounded, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text('Copy Profile Link',
              style: AppTheme.labelSmall.copyWith(color: AppTheme.primary)),
        ]),
      ),
    );
  }
}

// â”€â”€ Stats Grid â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _StatsGrid extends StatelessWidget {
  final int repos, stars, forks;
  final String lang;
  const _StatsGrid(
      {required this.repos, required this.stars,
       required this.forks, required this.lang});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.5,
      children: [
        _StatBox(label: 'Repos', value: '$repos',
            icon: Icons.code_rounded, color: AppTheme.primary),
        _StatBox(label: 'Stars', value: _fmt(stars),
            icon: Icons.star_rounded, color: AppTheme.warning),
        _StatBox(label: 'Forks', value: _fmt(forks),
            icon: Icons.fork_right_rounded, color: AppTheme.secondary),
        _StatBox(label: 'Top Lang', value: lang,
            icon: Icons.translate_rounded, color: AppTheme.accent,
            small: true),
      ],
    );
  }

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool small;
  const _StatBox({required this.label, required this.value,
      required this.icon, required this.color, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: small ? 11 : 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: AppTheme.bodySmall.copyWith(fontSize: 9)),
        ],
      ),
    );
  }
}

// â”€â”€ Skill Graph â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SkillGraph extends StatelessWidget {
  final List<MapEntry<String, int>> skills;
  const _SkillGraph({required this.skills});

  @override
  Widget build(BuildContext context) {
    final max = skills.first.value.toDouble();
    return Column(
      children: skills.asMap().entries.map((e) {
        final i = e.key;
        final skill = e.value;
        final pct = skill.value / max;
        final colors = [
          AppTheme.primary, AppTheme.secondary, const Color(0xFF9C6CFF),
          AppTheme.accent, AppTheme.warning,
        ];
        final color = colors[i % colors.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(skill.key,
                      style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.textSecondary, fontSize: 10)),
                  Text('${skill.value}x',
                      style: AppTheme.labelSmall.copyWith(
                          color: color, fontSize: 9)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Stack(children: [
                  Container(height: 5, color: AppTheme.surfaceHigh),
                  FractionallySizedBox(
                    widthFactor: pct,
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.5)]),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ).animate(delay: (i * 80).ms).slideX(begin: -1),
                ]),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// â”€â”€ Language Bubbles â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _LanguageBubbles extends StatelessWidget {
  final Map<String, double> languages;
  const _LanguageBubbles({required this.languages});

  @override
  Widget build(BuildContext context) {
    final total = languages.values.fold(0.0, (a, b) => a + b);
    final sorted = languages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: top.map((e) {
        final pct = (e.value / total * 100).toStringAsFixed(1);
        final color = AppTheme.languageColor(e.key);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 7, height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(e.key,
                style: AppTheme.labelSmall.copyWith(
                    color: color, fontSize: 10)),
            const SizedBox(width: 4),
            Text('$pct%',
                style: AppTheme.bodySmall.copyWith(fontSize: 9)),
          ]),
        );
      }).toList(),
    );
  }
}

// â”€â”€ About Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _AboutSection extends StatelessWidget {
  final int repoCount, liveCount, aiDoneCount, videoCount;
  const _AboutSection({
    required this.repoCount,
    required this.liveCount,
    required this.aiDoneCount,
    required this.videoCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AboutRow(Icons.rocket_launch_rounded, 'Projects showcased', '$repoCount'),
        _AboutRow(Icons.public_rounded, 'Live deployments', '$liveCount'),
        _AboutRow(Icons.auto_awesome_rounded, 'AI-analyzed', '$aiDoneCount'),
        _AboutRow(Icons.play_circle_outline_rounded, 'With demo video', '$videoCount'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
          ),
          child: Row(children: [
            const Icon(Icons.verified_rounded, size: 14, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Portfolio powered by Gemini AI & CodeSpotlight',
                style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primary.withValues(alpha: 0.8), fontSize: 10),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _AboutRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 13, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTheme.bodySmall.copyWith(fontSize: 11))),
        Text(value,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
      ]),
    );
  }
}

// â”€â”€ Shared helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 14, color: AppTheme.primary),
      const SizedBox(width: 7),
      Text(label.toUpperCase(),
          style: AppTheme.labelSmall.copyWith(
              color: AppTheme.textMuted,
              fontSize: 10,
              letterSpacing: 1.2)),
    ]);
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: AppTheme.border);
}

