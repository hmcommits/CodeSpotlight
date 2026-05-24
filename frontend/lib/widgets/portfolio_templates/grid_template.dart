import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';
import '../tech_icon.dart';

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

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildImage(String url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (url.startsWith('data:')) {
      final base64String = url.split(',').last;
      return Image.memory(base64Decode(base64String), width: width, height: height, fit: fit);
    }
    return Image.network(url, width: width, height: height, fit: fit);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [
                // 1, 2, 3, 5: Hero Bento Block
                _buildBentoBlock(
                  width: 700,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (user.avatarUrl.isNotEmpty)
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: user.avatarUrl.startsWith('data:') ? MemoryImage(base64Decode(user.avatarUrl.split(',').last)) as ImageProvider : NetworkImage(user.avatarUrl), fit: BoxFit.cover)),
                            )
                          else
                            CircleAvatar(radius: 40, backgroundColor: Colors.white10, child: Text(user.initial, style: GoogleFonts.outfit(fontSize: 32, color: Colors.white))),
                          const SizedBox(width: 24),
                          Expanded(child: Text(user.name, style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1))),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(user.bio, style: GoogleFonts.outfit(fontSize: 24, color: Colors.white70, height: 1.4)),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => _launch('mailto:${user.email}'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                            child: Text('Contact Me', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          if (user.resumeUrl.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            OutlinedButton(
                              onPressed: () => _launch(user.resumeUrl),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24, width: 2), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                              child: Text('Resume', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ]
                        ],
                      )
                    ],
                  ),
                ),

                // 4. Social Links Bento Block
                if (user.socialLinks.isNotEmpty)
                  _buildBentoBlock(
                    width: 350,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Connect', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white54)),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 16, runSpacing: 16,
                          children: user.socialLinks.entries.map((e) => InkWell(
                            onTap: () => _launch(e.value),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                              child: TechIcon(techName: e.key, size: 32),
                            ),
                          )).toList(),
                        )
                      ],
                    ),
                  ),

                // 6. Tech Stack Bento Block
                if (user.techStack.isNotEmpty)
                  _buildBentoBlock(
                    width: 500,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tech Stack', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white54)),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 16, runSpacing: 16,
                          children: user.techStack.map((tech) => Tooltip(
                            message: tech,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                              child: TechIcon(techName: tech, size: 32),
                            ),
                          )).toList(),
                        )
                      ],
                    ),
                  ),

                // 8. Experience Bento Blocks
                ...user.experiences.map((e) => _buildBentoBlock(
                  width: e.imageUrl.isNotEmpty ? 600 : 400,
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (e.imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                          child: _buildImage(e.imageUrl, width: double.infinity, height: 200),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.dates, style: GoogleFonts.outfit(color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text(e.role, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(e.company, style: GoogleFonts.outfit(fontSize: 18, color: Colors.white54)),
                            const SizedBox(height: 16),
                            Text(e.description, style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70, height: 1.5)),
                          ],
                        ),
                      )
                    ],
                  ),
                )),

                // 9. Achievement Bento Blocks
                ...user.achievements.map((a) => _buildBentoBlock(
                  width: 350,
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (a.imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                          child: _buildImage(a.imageUrl, width: double.infinity, height: 180),
                        )
                      else
                        Container(
                          height: 120, width: double.infinity,
                          decoration: const BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
                          child: const Center(child: Icon(LucideIcons.award, size: 48, color: Colors.white)),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 12),
                            Text(a.description, style: GoogleFonts.outfit(fontSize: 15, color: Colors.white70, height: 1.5)),
                          ],
                        ),
                      )
                    ],
                  ),
                )),

                // 7. Education Bento Blocks
                ...user.education.map((ed) => _buildBentoBlock(
                  width: 350,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(ed.dates, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      Text(ed.heading, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(ed.institution, style: GoogleFonts.outfit(fontSize: 16, color: Colors.white54)),
                      const SizedBox(height: 16),
                      Text(ed.description, style: GoogleFonts.outfit(fontSize: 15, color: Colors.white70, height: 1.5)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBentoBlock({required Widget child, required double width, EdgeInsets padding = const EdgeInsets.all(40)}) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1D),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
