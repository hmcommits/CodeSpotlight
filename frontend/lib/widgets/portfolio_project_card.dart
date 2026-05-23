import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PortfolioProjectCard extends StatelessWidget {
  final Project project;

  const PortfolioProjectCard({
    super.key,
    required this.project,
  });

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayDescription = project.customDescription.isNotEmpty
        ? project.customDescription
        : (project.aiSummary.isNotEmpty ? project.aiSummary : project.description);

    final langColor = AppTheme.languageColor(project.primaryLanguage);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name + Featured Crown + Language Badge
          Row(
            children: [
              Expanded(
                child: Text(
                  project.repo,
                  style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (project.featured) ...[
                const SizedBox(width: 8),
                const Icon(LucideIcons.award, color: AppTheme.warning, size: 20),
              ],
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: langColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: langColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: langColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      project.primaryLanguage,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: langColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Description
          Text(
            displayDescription,
            style: AppTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          
          // Tech Stack Chips
          if (project.techStack.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: project.techStack.take(4).map((tech) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  tech,
                  style: AppTheme.labelSmall.copyWith(color: AppTheme.textPrimary),
                ),
              )).toList(),
            ),
          
          const Spacer(),
          const SizedBox(height: 16),
          
          // Footer: Stats + Links
          Row(
            children: [
              _buildStat(LucideIcons.star, project.stars.toString(), AppTheme.warning),
              const SizedBox(width: 16),
              _buildStat(LucideIcons.gitFork, project.forks.toString(), AppTheme.textSecondary),
              const Spacer(),
              if (project.liveUrl.isNotEmpty)
                IconButton(
                  icon: const Icon(LucideIcons.externalLink, size: 20),
                  color: AppTheme.primary,
                  onPressed: () => _launchUrl(project.liveUrl),
                  tooltip: 'View Live App',
                ),
              IconButton(
                icon: const Icon(LucideIcons.github, size: 20),
                color: AppTheme.textPrimary,
                onPressed: () => _launchUrl('https://github.com/${project.fullName}'),
                tooltip: 'View Source',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
