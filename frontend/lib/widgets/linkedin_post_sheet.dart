import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';

/// Shows a bottom sheet with a generated LinkedIn post for the given project.
void showLinkedInPostSheet(BuildContext context, Project project) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LinkedInPostSheet(project: project),
  );
}

class _LinkedInPostSheet extends StatefulWidget {
  final Project project;
  const _LinkedInPostSheet({required this.project});

  @override
  State<_LinkedInPostSheet> createState() => _LinkedInPostSheetState();
}

class _LinkedInPostSheetState extends State<_LinkedInPostSheet> {
  late final String _postText;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _postText = _generatePost(widget.project);
  }

  static String _generatePost(Project p) {
    final hasLive = p.liveUrl.isNotEmpty;
    final hasVideo = p.videoUrl.isNotEmpty;
    final githubUrl = 'https://github.com/${p.fullName}';
    final techList = p.techStack.take(5).join(' · ');
    final hashtags = p.techStack
        .take(4)
        .map((t) => '#${t.replaceAll(' ', '').replaceAll('-', '').replaceAll('.', '')}')
        .join(' ');

    // Use AI summary paragraph if available, else fall back to description
    String insight = '';
    if (p.aiSummary.isNotEmpty) {
      // Take the first paragraph of the AI summary (up to 200 chars)
      final first = p.aiSummary.split('\n').first.trim();
      insight = first.length > 200 ? '${first.substring(0, 197)}...' : first;
    } else if (p.description.isNotEmpty) {
      insight = p.description;
    }

    final buffer = StringBuffer();
    buffer.writeln('🚀 Excited to share my latest project — ${p.repo}!');
    buffer.writeln();
    if (insight.isNotEmpty) {
      buffer.writeln(insight);
      buffer.writeln();
    }
    buffer.writeln('🏗️ What makes it interesting:');
    buffer.writeln('• Built with $techList');
    if (p.stars > 0) buffer.writeln('• ⭐ ${p.stars} GitHub stars');
    if (hasLive) buffer.writeln('• 🌐 Live at: ${p.liveUrl}');
    buffer.writeln();
    buffer.writeln('📂 View the full code → $githubUrl');
    if (hasVideo) buffer.writeln('🎬 Demo video → ${p.videoUrl}');
    buffer.writeln();
    buffer.writeln('Showcased with CodeSpotlight ✨ — AI-powered developer portfolio');
    buffer.writeln();
    buffer.writeln('#OpenSource $hashtags #SoftwareEngineering #DevCommunity');

    return buffer.toString().trim();
  }

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: _postText));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _shareToLinkedIn() async {
    final githubUrl = 'https://github.com/${widget.project.fullName}';
    final shareUrl = Uri.parse(
      'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(githubUrl)}',
    );
    // Copy text first so user can paste it
    await Clipboard.setData(ClipboardData(text: _postText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Post text copied! Paste it on LinkedIn'),
          backgroundColor: const Color(0xFF0A66C2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
    if (await canLaunchUrl(shareUrl)) {
      await launchUrl(shareUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              // LinkedIn logo SVG-style icon
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A66C2),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text('in',
                    style: TextStyle(color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.w900,
                        fontFamily: 'serif')),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('LinkedIn Post',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                Text('Tap copy, then paste on LinkedIn',
                    style: AppTheme.bodySmall.copyWith(fontSize: 11)),
              ]),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),

          const SizedBox(height: 16),
          Divider(color: AppTheme.border, height: 1),

          // Post preview
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      // Mini avatar
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text('Y',
                            style: TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 10),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('You',
                            style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600)),
                        Text('Software Developer',
                            style: AppTheme.bodySmall.copyWith(fontSize: 11)),
                      ]),
                    ]),
                    const SizedBox(height: 14),
                    SelectableText(
                      _postText,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.7),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: Row(children: [
              Expanded(
                child: _ActionButton(
                  label: _copied ? 'Copied!' : 'Copy Post',
                  icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                  onTap: _copyText,
                  outlined: true,
                  color: _copied ? AppTheme.success : AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'Share to LinkedIn',
                  icon: Icons.open_in_new_rounded,
                  onTap: _shareToLinkedIn,
                  color: const Color(0xFF0A66C2),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;
  final Color color;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.outlined = false,
    required this.color,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: widget.outlined
                ? (_hov ? widget.color.withValues(alpha: 0.12) : Colors.transparent)
                : (_hov ? widget.color.withValues(alpha: 0.85) : widget.color),
            borderRadius: BorderRadius.circular(12),
            border: widget.outlined
                ? Border.all(color: widget.color, width: 1.5)
                : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(widget.icon, size: 15,
                color: widget.outlined ? widget.color : Colors.white),
            const SizedBox(width: 7),
            Text(widget.label,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: widget.outlined ? widget.color : Colors.white)),
          ]),
        ),
      ),
    );
  }
}
