import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';
import '../tech_icon.dart';

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
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
            children: [
              // 1 & 2. Avatar and Header
              Center(
                child: Column(
                  children: [
                    if (user.avatarUrl.isNotEmpty)
                      Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: user.avatarUrl.startsWith('data:') 
                                ? MemoryImage(base64Decode(user.avatarUrl.split(',').last)) as ImageProvider
                                : NetworkImage(user.avatarUrl),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                          ]
                        ),
                      )
                    else
                      Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          user.initial,
                          style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                      ),
                    const SizedBox(height: 32),
                    Text(
                      user.name,
                      style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w900, color: const Color(0xFF111111), letterSpacing: -1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Bio
              Text(
                user.bio,
                style: GoogleFonts.inter(fontSize: 20, color: const Color(0xFF555555), height: 1.6, fontWeight: FontWeight.w400),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // 4. Social Links (Visual logos only)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: user.socialLinks.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: InkWell(
                      onTap: () => _launch(e.value),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TechIcon(
                          techName: e.key,
                          size: 24,
                          colorHex: '333333',
                          fallbackStyle: GoogleFonts.inter(color: const Color(0xFF333333), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 48),

              // 5. Call to Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _launch('mailto:${user.email}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111111),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                      elevation: 0,
                    ),
                    child: const Text('Contact Me'),
                  ),
                  if (user.resumeUrl.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () => _launch(user.resumeUrl),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF111111),
                        side: const BorderSide(color: Color(0xFF111111), width: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Resume'),
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 80),

              // 6. What I Do & Tech Stack
              if (user.techStack.isNotEmpty) ...[
                _SectionHeading('Tech Stack'),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  alignment: WrapAlignment.center,
                  children: user.techStack.map((tech) => Tooltip(
                    message: tech,
                    child: Container(
                      width: 64, height: 64,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: TechIcon(
                        techName: tech,
                        size: 32,
                        colorHex: '333333',
                        fallbackStyle: GoogleFonts.inter(color: const Color(0xFF333333), fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 80),
              ],

              // 7. Education
              if (user.education.isNotEmpty) ...[
                _SectionHeading('Education'),
                const SizedBox(height: 32),
                ...user.education.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(e.dates, style: GoogleFonts.inter(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.heading, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF111111))),
                            const SizedBox(height: 4),
                            Text(e.institution, style: GoogleFonts.inter(fontSize: 16, color: Colors.blue.shade700, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Text(e.description, style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF555555), height: 1.5)),
                          ],
                        ),
                      )
                    ],
                  ),
                )),
                const SizedBox(height: 56),
              ],

              // 8. Experiences
              if (user.experiences.isNotEmpty) ...[
                _SectionHeading('Experience'),
                const SizedBox(height: 32),
                ...user.experiences.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.role, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF111111))),
                                const SizedBox(height: 4),
                                Text('${e.company} • ${e.dates}', style: GoogleFonts.inter(fontSize: 15, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(e.description, style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF555555), height: 1.6)),
                      if (e.imageUrl.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildImage(e.imageUrl, width: double.infinity, height: 200),
                        ),
                      ]
                    ],
                  ),
                )),
                const SizedBox(height: 48),
              ],

              // 9. Achievements & Certificates
              if (user.achievements.isNotEmpty) ...[
                _SectionHeading('Achievements'),
                const SizedBox(height: 32),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: user.achievements.length,
                  itemBuilder: (ctx, i) {
                    final a = user.achievements[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (a.imageUrl.isNotEmpty)
                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                width: double.infinity,
                                child: _buildImage(a.imageUrl),
                              ),
                            )
                          else
                            Expanded(
                              flex: 3,
                              child: Container(
                                color: Colors.grey.shade50,
                                child: const Center(child: Icon(LucideIcons.award, size: 48, color: Colors.grey)),
                              ),
                            ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF111111)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  Text(a.description, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF666666), height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ),
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
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  const _SectionHeading(this.title);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFF111111), letterSpacing: -1),
        ),
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.blue.shade600, borderRadius: BorderRadius.circular(2))),
      ],
    );
  }
}
