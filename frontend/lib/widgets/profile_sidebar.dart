import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../models/project_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
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

  // ── Computed aggregates ───────────────────────────────────────────────────

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
    return sorted.take(8).toList();
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
    final screenH = MediaQuery.of(context).size.height;
    final name = user?.name.isNotEmpty == true
        ? user!.name
        : isDemo ? 'Demo User' : 'Developer';
    final initial = user?.initial ?? (isDemo ? 'D' : 'U');
    final email = user?.email ?? '';

    return SizedBox(
      width: 340,
      height: screenH,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(right: BorderSide(color: AppTheme.border)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // ── Avatar ────────────────────────────────────────────────────
              _Avatar(initial: initial),
              const SizedBox(height: 16),

              Text(
                name,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(email,
                    style: AppTheme.bodyMedium.copyWith(fontSize: 13),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis),
              ],
              if (isDemo) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.secondary.withValues(alpha: 0.3)),
                  ),
                  child: Text('Demo Mode',
                      style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w600)),
                ),
              ],

              const SizedBox(height: 16),

              // ── Social Links ──────────────────────────────────────────────
              if (user != null && !isDemo) ...[
                _SocialLinksRow(user: user!),
                const SizedBox(height: 16),
              ],

              // ── Share link ───────────────────────────────────────────────
              if (!isDemo && user != null) ...[
                _ShareProfileButton(userId: user!.id),
                const SizedBox(height: 12),
                const _PortfolioEditorButton(),
                const SizedBox(height: 20),
              ],

              _Divider(),

              // ── Stats ─────────────────────────────────────────────────────
              const SizedBox(height: 20),
              _SectionHeader(
                  icon: Icons.bar_chart_rounded, label: 'Portfolio Stats'),
              const SizedBox(height: 14),
              _StatsGrid(
                repos: projects.length,
                stars: _totalStars,
                forks: _totalForks,
                lang: _topLanguage,
              ),

              const SizedBox(height: 20),
              _Divider(),

              // ── Skills ────────────────────────────────────────────────────
              if (_topSkills.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionHeader(
                    icon: Icons.psychology_rounded, label: 'Top Skills'),
                const SizedBox(height: 14),
                _SkillGraph(skills: _topSkills),
                const SizedBox(height: 20),
                _Divider(),
              ],

              // ── Languages ─────────────────────────────────────────────────
              if (_combinedLanguages.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionHeader(
                    icon: Icons.bubble_chart_rounded, label: 'Languages'),
                const SizedBox(height: 14),
                _LanguageBubbles(languages: _combinedLanguages),
                const SizedBox(height: 20),
                _Divider(),
              ],

              // ── About ────────────────────────────────────────────────────
              const SizedBox(height: 20),
              _SectionHeader(
                  icon: Icons.info_outline_rounded, label: 'About'),
              const SizedBox(height: 14),
              _AboutSection(
                repoCount: projects.length,
                liveCount:
                    projects.where((p) => p.liveUrl.isNotEmpty).length,
                aiDoneCount:
                    projects.where((p) => p.aiStatus == 'done').length,
                videoCount:
                    projects.where((p) => p.videoUrl.isNotEmpty).length,
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String initial;
  const _Avatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.45),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Share Profile Button ──────────────────────────────────────────────────────
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.35)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.link_rounded, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text('Copy Profile Link',
              style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ── Portfolio Editor Button ───────────────────────────────────────────────────
class _PortfolioEditorButton extends StatelessWidget {
  const _PortfolioEditorButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/app/portfolio'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.secondary.withValues(alpha: 0.35)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.brush_rounded, size: 16, color: AppTheme.secondary),
          const SizedBox(width: 8),
          Text('My Portfolio',
              style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ── Social Links Row ──────────────────────────────────────────────────────────
class _SocialLinksRow extends StatefulWidget {
  final AppUser user;
  const _SocialLinksRow({required this.user});
  @override
  State<_SocialLinksRow> createState() => _SocialLinksRowState();
}

class _SocialLinksRowState extends State<_SocialLinksRow> {
  Future<void> _launch(String url) async {
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _editLinks() async {
    final links = widget.user.socialLinks;
    final ghCtrl = TextEditingController(text: links['github'] ?? '');
    final inCtrl = TextEditingController(text: links['linkedin'] ?? '');
    final twCtrl = TextEditingController(text: links['twitter'] ?? '');
    final ptCtrl = TextEditingController(text: links['portfolio'] ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Edit Social Links', style: AppTheme.titleMedium),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LinkField(ctrl: ghCtrl, label: 'GitHub URL', icon: FontAwesomeIcons.github),
              const SizedBox(height: 12),
              _LinkField(ctrl: inCtrl, label: 'LinkedIn URL', icon: FontAwesomeIcons.linkedin),
              const SizedBox(height: 12),
              _LinkField(ctrl: twCtrl, label: 'Twitter/X URL', icon: FontAwesomeIcons.twitter),
              const SizedBox(height: 12),
              _LinkField(ctrl: ptCtrl, label: 'Portfolio URL', icon: Icons.language),
            ],
          ),
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

    if (saved == true) {
      try {
        final updated = await ApiService.updateUser(socialLinks: {
          'github': ghCtrl.text.trim(),
          'linkedin': inCtrl.text.trim(),
          'twitter': twCtrl.text.trim(),
          'portfolio': ptCtrl.text.trim(),
        });
        await AuthService.instance.updateUser(updated);
        // Force rebuild or let listeners handle it
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final links = widget.user.socialLinks;
    final hasLinks = links.values.any((v) => v.isNotEmpty);
    // Only the logged in user can edit their own links
    final isMe = AuthService.instance.user?.id == widget.user.id;

    if (!hasLinks && !isMe) return const SizedBox();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (links['github']?.isNotEmpty == true)
          _SocialBtn(icon: FontAwesomeIcons.github, onTap: () => _launch(links['github']!)),
        if (links['linkedin']?.isNotEmpty == true)
          _SocialBtn(icon: FontAwesomeIcons.linkedin, onTap: () => _launch(links['linkedin']!)),
        if (links['twitter']?.isNotEmpty == true)
          _SocialBtn(icon: FontAwesomeIcons.twitter, onTap: () => _launch(links['twitter']!)),
        if (links['portfolio']?.isNotEmpty == true)
          _SocialBtn(icon: Icons.language, onTap: () => _launch(links['portfolio']!)),
        if (isMe)
          IconButton(
            icon: Icon(hasLinks ? Icons.edit_rounded : Icons.add_link_rounded, size: 22),
            color: AppTheme.primary,
            tooltip: 'Edit Links',
            onPressed: _editLinks,
          ),
      ],
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final dynamic icon;
  final VoidCallback onTap;
  const _SocialBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: icon is IconData ? Icon(icon as IconData, size: 24) : FaIcon(icon, size: 24),
      color: AppTheme.textSecondary,
      onPressed: onTap,
      hoverColor: AppTheme.primary.withValues(alpha: 0.1),
    );
  }
}

class _LinkField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final dynamic icon;
  const _LinkField({required this.ctrl, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: icon is IconData ? Icon(icon as IconData, size: 16) : FaIcon(icon, size: 16),
        ),
      ),
    );
  }
}

// ── Stats Grid ────────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final int repos, stars, forks;
  final String lang;
  const _StatsGrid(
      {required this.repos,
      required this.stars,
      required this.forks,
      required this.lang});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        _StatBox(
            label: 'Repos',
            value: '$repos',
            icon: Icons.code_rounded,
            color: AppTheme.primary),
        _StatBox(
            label: 'Stars',
            value: _fmt(stars),
            icon: Icons.star_rounded,
            color: AppTheme.warning),
        _StatBox(
            label: 'Forks',
            value: _fmt(forks),
            icon: Icons.fork_right_rounded,
            color: AppTheme.secondary),
        _StatBox(
            label: 'Top Lang',
            value: lang,
            icon: Icons.translate_rounded,
            color: AppTheme.accent,
            small: true),
      ],
    );
  }

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool small;
  const _StatBox(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: small ? 13 : 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: AppTheme.bodySmall.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Skill Graph ───────────────────────────────────────────────────────────────
class _SkillGraph extends StatelessWidget {
  final List<MapEntry<String, int>> skills;
  const _SkillGraph({required this.skills});

  static const _colors = [
    Color(0xFF6C63FF),
    Color(0xFF00D4AA),
    Color(0xFF9C6CFF),
    Color(0xFFFF6B6B),
    Color(0xFFFFB347),
  ];

  @override
  Widget build(BuildContext context) {
    final max = skills.first.value.toDouble();
    return Column(
      children: skills.asMap().entries.map((e) {
        final i = e.key;
        final skill = e.value;
        final pct = skill.value / max;
        final color = _colors[i % _colors.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(skill.key,
                      style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary, fontSize: 13)),
                  Text('${skill.value}x',
                      style: AppTheme.labelSmall.copyWith(
                          color: color, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(children: [
                  Container(height: 7, color: AppTheme.surfaceHigh),
                  FractionallySizedBox(
                    widthFactor: pct,
                    child: Container(
                      height: 7,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          color,
                          color.withValues(alpha: 0.5)
                        ]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Language Bubbles ──────────────────────────────────────────────────────────
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
      spacing: 8,
      runSpacing: 8,
      children: top.map((e) {
        final pct = (e.value / total * 100).toStringAsFixed(1);
        final color = AppTheme.languageColor(e.key);
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(e.key,
                style: AppTheme.bodyMedium.copyWith(
                    color: color, fontSize: 12)),
            const SizedBox(width: 5),
            Text('$pct%',
                style: AppTheme.bodySmall.copyWith(fontSize: 10)),
          ]),
        );
      }).toList(),
    );
  }
}

// ── About Section ─────────────────────────────────────────────────────────────
class _AboutSection extends StatelessWidget {
  final int repoCount, liveCount, aiDoneCount, videoCount;
  const _AboutSection(
      {required this.repoCount,
      required this.liveCount,
      required this.aiDoneCount,
      required this.videoCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AboutRow(Icons.rocket_launch_rounded, 'Projects showcased',
            '$repoCount'),
        _AboutRow(Icons.public_rounded, 'Live deployments', '$liveCount'),
        _AboutRow(Icons.auto_awesome_rounded, 'AI-analyzed', '$aiDoneCount'),
        _AboutRow(Icons.play_circle_outline_rounded, 'With demo video',
            '$videoCount'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
          ),
          child: Row(children: [
            const Icon(Icons.verified_rounded,
                size: 16, color: AppTheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Portfolio powered by Gemini AI & CodeSpotlight',
                style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primary.withValues(alpha: 0.8),
                    fontSize: 11),
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
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Icon(icon, size: 15, color: AppTheme.textMuted),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style: AppTheme.bodyMedium.copyWith(fontSize: 13))),
        Text(value,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
      ]),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppTheme.primary),
      const SizedBox(width: 8),
      Text(label.toUpperCase(),
          style: AppTheme.labelSmall.copyWith(
              color: AppTheme.textMuted,
              fontSize: 11,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700)),
    ]);
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: AppTheme.border);
}
