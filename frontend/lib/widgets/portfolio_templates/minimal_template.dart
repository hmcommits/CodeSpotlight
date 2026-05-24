import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';
import '../portfolio_project_card.dart';

class MinimalTemplate extends StatelessWidget {
  final AppUser user;
  final List<Project> projects;
  final Map<String, dynamic> stats;

  const MinimalTemplate({
    super.key,
    required this.user,
    required this.projects,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
            children: [
              // Hero Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user.avatarUrl.isNotEmpty)
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(user.avatarUrl),
                      backgroundColor: Colors.grey.shade200,
                    )
                  else
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade200,
                      child: Text(
                        user.initial,
                        style: GoogleFonts.inter(fontSize: 32, color: Colors.black54),
                      ),
                    ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.bio,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (user.socialLinks.containsKey('github'))
                              _SocialIcon(LucideIcons.github, user.socialLinks['github']!),
                            if (user.socialLinks.containsKey('linkedin'))
                              _SocialIcon(LucideIcons.linkedin, user.socialLinks['linkedin']!),
                            if (user.socialLinks.containsKey('twitter'))
                              _SocialIcon(LucideIcons.twitter, user.socialLinks['twitter']!),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 64),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(label: 'Repositories', value: stats['totalRepos']?.toString() ?? '0'),
                  _StatItem(label: 'Total Stars', value: stats['totalStars']?.toString() ?? '0'),
                  _StatItem(label: 'Deployments', value: stats['liveDeployments']?.toString() ?? '0'),
                ],
              ),
              const SizedBox(height: 64),

              // Projects
              Text(
                'Projects',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              ...projects.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _MinimalProjectCard(project: p),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }
}

class _MinimalProjectCard extends StatelessWidget {
  final Project project;
  const _MinimalProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    // We override the default PortfolioProjectCard's dark theme for minimal
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                project.repo,
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const Spacer(),
              if (project.featured)
                Icon(LucideIcons.award, size: 16, color: Colors.orange),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            project.customDescription.isNotEmpty ? project.customDescription : project.description,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(LucideIcons.circle, size: 12, color: Colors.blue.shade300),
              const SizedBox(width: 4),
              Text(project.primaryLanguage, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
              const SizedBox(width: 16),
              Icon(LucideIcons.star, size: 14, color: Colors.black54),
              const SizedBox(width: 4),
              Text(project.stars.toString(), style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
            ],
          )
        ],
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final String url;
  const _SocialIcon(this.icon, this.url);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: IconButton(
        icon: Icon(icon, color: Colors.black87),
        onPressed: () {
          // Launch URL
        },
      ),
    );
  }
}
