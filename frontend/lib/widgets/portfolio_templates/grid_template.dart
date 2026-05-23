import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../portfolio_project_card.dart';

class GridTemplate extends StatelessWidget {
  final AppUser user;
  final List<Project> projects;
  final Map<String, dynamic> stats;

  const GridTemplate({
    super.key,
    required this.user,
    required this.projects,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bento Box
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHigh,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard * 2),
                    border: Border.all(color: AppTheme.border),
                  ),
                  padding: const EdgeInsets.all(40),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.surfaceLight,
                        backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                        child: user.avatarUrl.isEmpty ? Text(user.initial, style: AppTheme.displayLarge) : null,
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: AppTheme.displayLarge),
                            const SizedBox(height: 8),
                            Text(user.bio, style: AppTheme.bodyMedium.copyWith(fontSize: 16)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _StatChip(LucideIcons.box, '${stats['totalRepos']} Repos'),
                                const SizedBox(width: 12),
                                _StatChip(LucideIcons.star, '${stats['totalStars']} Stars'),
                                const SizedBox(width: 12),
                                _StatChip(LucideIcons.globe, '${stats['liveDeployments']} Deploys'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          if (user.socialLinks.containsKey('github'))
                            IconButton(icon: const Icon(LucideIcons.github, color: AppTheme.textPrimary), onPressed: () {}),
                          if (user.socialLinks.containsKey('linkedin'))
                            IconButton(icon: const Icon(LucideIcons.linkedin, color: AppTheme.secondary), onPressed: () {}),
                          if (user.socialLinks.containsKey('twitter'))
                            IconButton(icon: const Icon(LucideIcons.twitter, color: AppTheme.primary), onPressed: () {}),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                Text('Projects', style: AppTheme.titleLarge),
                const SizedBox(height: 24),

                // Masonry/Grid of projects
                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: 0.8, // Adjust based on card content
                      ),
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        return PortfolioProjectCard(project: projects[index]);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.secondary),
          const SizedBox(width: 8),
          Text(label, style: AppTheme.labelSmall.copyWith(color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
