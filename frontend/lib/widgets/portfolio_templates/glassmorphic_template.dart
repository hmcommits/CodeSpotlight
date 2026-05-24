import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';

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
      body: Stack(
        children: [
          // Vibrant Animated Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2), Color(0xFFF000FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Floating background orbs
          Positioned(top: -100, left: -100, child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent.withOpacity(0.5)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: const SizedBox()))),
          Positioned(bottom: -100, right: -100, child: Container(width: 500, height: 500, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.orangeAccent.withOpacity(0.5)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: const SizedBox()))),
          
          // Scrollable Content
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
                children: [
                  // 1 & 2: Header & Avatar
                  _GlassContainer(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        if (user.avatarUrl.isNotEmpty)
                          Container(
                            width: 150, height: 150,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.5), width: 3), image: DecorationImage(image: user.avatarUrl.startsWith('data:') ? MemoryImage(base64Decode(user.avatarUrl.split(',').last)) as ImageProvider : NetworkImage(user.avatarUrl), fit: BoxFit.cover)),
                          )
                        else
                          Container(
                            width: 150, height: 150,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1), border: Border.all(color: Colors.white.withOpacity(0.5), width: 3)),
                            alignment: Alignment.center,
                            child: Text(user.initial, style: GoogleFonts.poppins(fontSize: 64, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        const SizedBox(height: 24),
                        Text(user.name, style: GoogleFonts.poppins(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        // 3. Bio
                        Text(user.bio, style: GoogleFonts.poppins(fontSize: 20, color: Colors.white.withOpacity(0.9), height: 1.5), textAlign: TextAlign.center),
                        const SizedBox(height: 32),
                        
                        // 4. Social Links
                        if (user.socialLinks.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: user.socialLinks.entries.map((e) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: InkWell(
                                onTap: () => _launch(e.value),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1), border: Border.all(color: Colors.white.withOpacity(0.3))),
                                  child: Image.network('https://cdn.simpleicons.org/${e.key.toLowerCase()}/ffffff', width: 24, height: 24, errorBuilder: (_,__,___) => const Icon(LucideIcons.link, color: Colors.white)),
                                ),
                              ),
                            )).toList(),
                          ),
                          const SizedBox(height: 48),
                        ],

                        // 5. CTA Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () => _launch('mailto:${user.email}'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.purple, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                              child: Text('Contact Me', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                            ),
                            if (user.resumeUrl.isNotEmpty) ...[
                              const SizedBox(width: 20),
                              OutlinedButton(
                                onPressed: () => _launch(user.resumeUrl),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white, width: 2), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                                child: Text('Resume', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                              ),
                            ]
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 6. Tech Stack
                  if (user.techStack.isNotEmpty) ...[
                    Text('Tech Stack', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 24),
                    _GlassContainer(
                      child: Wrap(
                        spacing: 24, runSpacing: 24, alignment: WrapAlignment.center,
                        children: user.techStack.map((tech) => Tooltip(
                          message: tech,
                          child: Container(
                            width: 80, height: 80,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.2))),
                            child: Image.network('https://cdn.simpleicons.org/${tech.toLowerCase().replaceAll(' ', '')}/ffffff', errorBuilder: (_,__,___) => Center(child: Text(tech[0].toUpperCase(), style: GoogleFonts.poppins(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)))),
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],

                  // 7. Education
                  if (user.education.isNotEmpty) ...[
                    Text('Education', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 24),
                    ...user.education.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _GlassContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                              child: Text(e.dates, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 16),
                            Text(e.heading, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(e.institution, style: GoogleFonts.poppins(fontSize: 18, color: Colors.white.withOpacity(0.8))),
                            const SizedBox(height: 16),
                            Text(e.description, style: GoogleFonts.poppins(fontSize: 16, color: Colors.white.withOpacity(0.9), height: 1.5)),
                          ],
                        ),
                      ),
                    )),
                    const SizedBox(height: 48),
                  ],

                  // 8. Experiences
                  if (user.experiences.isNotEmpty) ...[
                    Text('Experience', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 24),
                    ...user.experiences.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: _GlassContainer(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (e.imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                child: _buildImage(e.imageUrl, width: double.infinity, height: 250),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.dates, style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  Text(e.role, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                                  Text(e.company, style: GoogleFonts.poppins(fontSize: 20, color: Colors.white.withOpacity(0.9))),
                                  const SizedBox(height: 16),
                                  Text(e.description, style: GoogleFonts.poppins(fontSize: 16, color: Colors.white.withOpacity(0.9), height: 1.5)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    )),
                    const SizedBox(height: 48),
                  ],

                  // 9. Achievements
                  if (user.achievements.isNotEmpty) ...[
                    Text('Achievements', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 24),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 400, mainAxisSpacing: 24, crossAxisSpacing: 24, childAspectRatio: 0.8),
                      itemCount: user.achievements.length,
                      itemBuilder: (ctx, i) {
                        final a = user.achievements[i];
                        return _GlassContainer(
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (a.imageUrl.isNotEmpty)
                                Expanded(flex: 3, child: SizedBox(width: double.infinity, child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), child: _buildImage(a.imageUrl))))
                              else
                                Expanded(flex: 3, child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))), alignment: Alignment.center, child: const Icon(LucideIcons.award, size: 64, color: Colors.white))),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a.title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 8),
                                      Text(a.description, style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withOpacity(0.8), height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 80),
                  ],
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _GlassContainer({required this.child, this.padding = const EdgeInsets.all(32)});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, spreadRadius: -5)],
          ),
          child: child,
        ),
      ),
    );
  }
}
