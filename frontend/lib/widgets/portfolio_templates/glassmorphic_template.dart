import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../portfolio_project_card.dart';

class GlassmorphicTemplate extends StatelessWidget {
  final AppUser user;
  final List<Project> projects;
  final Map<String, dynamic> stats;

  const GlassmorphicTemplate({
    super.key,
    required this.user,
    required this.projects,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Floating Orbs
          Positioned(top: -100, left: -100, child: _Orb(color: Colors.purple.withOpacity(0.5))),
          Positioned(bottom: -50, right: 100, child: _Orb(color: Colors.blue.withOpacity(0.5))),
          Positioned(top: 300, right: -50, child: _Orb(color: Colors.pink.withOpacity(0.4))),
          
          // Content
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sidebar
                    Expanded(
                      flex: 1,
                      child: _GlassCard(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                              backgroundColor: Colors.white24,
                              child: user.avatarUrl.isEmpty ? Text(user.initial, style: AppTheme.displayLarge) : null,
                            ),
                            const SizedBox(height: 24),
                            Text(user.name, style: AppTheme.headlineMedium, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            Text(user.bio, style: AppTheme.bodyMedium, textAlign: TextAlign.center),
                            const SizedBox(height: 32),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 32),
                            _StatRow('Repositories', stats['totalRepos'].toString()),
                            _StatRow('Stars', stats['totalStars'].toString()),
                            _StatRow('Deployments', stats['liveDeployments'].toString()),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    
                    // Main Content (Projects)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Showcase', style: AppTheme.displayLarge),
                          const SizedBox(height: 24),
                          ...projects.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: _GlassCard(
                              padding: EdgeInsets.zero,
                              child: PortfolioProjectCard(project: p),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final Color color;
  const _Orb({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _GlassCard({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyMedium),
          Text(value, style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
