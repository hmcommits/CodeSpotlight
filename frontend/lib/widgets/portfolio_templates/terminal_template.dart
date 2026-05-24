import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';

class TerminalTemplate extends StatelessWidget {
  final AppUser user;
  final List<Project> projects;
  final Map<String, dynamic> stats;

  const TerminalTemplate({
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
      backgroundColor: const Color(0xFF0C0C0C),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: const Color(0xFF333333)),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.05), blurRadius: 30)],
            ),
            child: Column(
              children: [
                // Window Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                      const SizedBox(width: 16),
                      Text('${user.portfolioSlug.isNotEmpty ? user.portfolioSlug : 'user'}@codespotlight: ~', style: GoogleFonts.firaCode(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                // Terminal Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(32),
                    children: [
                      // 1, 2, 3: Header, Avatar, Bio
                      _Prompt(command: 'whoami'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (user.avatarUrl.isNotEmpty)
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.greenAccent, width: 2),
                                image: DecorationImage(image: user.avatarUrl.startsWith('data:') ? MemoryImage(base64Decode(user.avatarUrl.split(',').last)) as ImageProvider : NetworkImage(user.avatarUrl), fit: BoxFit.cover),
                              ),
                            ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('NAME: ${user.name}', style: GoogleFonts.firaCode(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                                const SizedBox(height: 8),
                                Text('BIO: ${user.bio}', style: GoogleFonts.firaCode(fontSize: 16, color: Colors.white70, height: 1.5)),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 4. Social Links
                      if (user.socialLinks.isNotEmpty) ...[
                        _Prompt(command: 'ls -l ~/socials/'),
                        Wrap(
                          spacing: 16, runSpacing: 16,
                          children: user.socialLinks.entries.map((e) => InkWell(
                            onTap: () => _launch(e.value),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.network('https://cdn.simpleicons.org/${e.key.toLowerCase()}/00FF00', width: 20, height: 20, placeholderBuilder: (_) => const Icon(LucideIcons.link, color: Colors.greenAccent, size: 20)),
                                const SizedBox(width: 8),
                                Text('${e.key}.sh', style: GoogleFonts.firaCode(color: Colors.greenAccent)),
                              ],
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // 5. Call to Action
                      _Prompt(command: './execute_actions.sh'),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => _launch('mailto:${user.email}'),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.greenAccent, side: const BorderSide(color: Colors.greenAccent), shape: const RoundedRectangleBorder()),
                            child: Text('contact_me.exe', style: GoogleFonts.firaCode()),
                          ),
                          if (user.resumeUrl.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            OutlinedButton(
                              onPressed: () => _launch(user.resumeUrl),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white70), shape: const RoundedRectangleBorder()),
                              child: Text('resume.pdf', style: GoogleFonts.firaCode()),
                            ),
                          ]
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 6. Tech Stack
                      if (user.techStack.isNotEmpty) ...[
                        _Prompt(command: 'cat ~/.config/tech_stack.json'),
                        Wrap(
                          spacing: 16, runSpacing: 16,
                          children: user.techStack.map((tech) => Tooltip(
                            message: tech,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(border: Border.all(color: Colors.greenAccent.withOpacity(0.3))),
                              child: SvgPicture.network('https://cdn.simpleicons.org/${tech.toLowerCase().replaceAll(' ', '')}/00FF00', width: 32, height: 32, placeholderBuilder: (_) => Text(tech[0].toUpperCase(), style: GoogleFonts.firaCode(fontSize: 24, color: Colors.greenAccent, fontWeight: FontWeight.bold))),
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // 7. Education
                      if (user.education.isNotEmpty) ...[
                        _Prompt(command: 'history | grep education'),
                        ...user.education.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('[${e.dates}] ${e.heading}', style: GoogleFonts.firaCode(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                              Text('@ ${e.institution}', style: GoogleFonts.firaCode(color: Colors.white70)),
                              const SizedBox(height: 4),
                              Text('> ${e.description}', style: GoogleFonts.firaCode(color: Colors.white54)),
                            ],
                          ),
                        )),
                        const SizedBox(height: 32),
                      ],

                      // 8. Experiences
                      if (user.experiences.isNotEmpty) ...[
                        _Prompt(command: 'cat /var/log/experiences.log'),
                        ...user.experiences.map((e) => Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(border: Border.all(color: Colors.greenAccent.withOpacity(0.2))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${e.role} @ ${e.company}', style: GoogleFonts.firaCode(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('TIME: ${e.dates}', style: GoogleFonts.firaCode(color: Colors.greenAccent)),
                              const SizedBox(height: 12),
                              Text(e.description, style: GoogleFonts.firaCode(color: Colors.white70, height: 1.5)),
                              if (e.imageUrl.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(border: Border.all(color: Colors.greenAccent)),
                                  child: _buildImage(e.imageUrl, width: double.infinity, height: 200),
                                ),
                              ]
                            ],
                          ),
                        )),
                        const SizedBox(height: 32),
                      ],

                      // 9. Achievements
                      if (user.achievements.isNotEmpty) ...[
                        _Prompt(command: 'ls -al ~/achievements/'),
                        Wrap(
                          spacing: 24, runSpacing: 24,
                          children: user.achievements.map((a) => Container(
                            width: 250,
                            decoration: BoxDecoration(border: Border.all(color: Colors.greenAccent.withOpacity(0.3))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (a.imageUrl.isNotEmpty)
                                  _buildImage(a.imageUrl, width: double.infinity, height: 140)
                                else
                                  Container(height: 140, color: Colors.white10, alignment: Alignment.center, child: const Icon(LucideIcons.award, color: Colors.greenAccent, size: 48)),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a.title, style: GoogleFonts.firaCode(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Text(a.description, style: GoogleFonts.firaCode(color: Colors.white54, fontSize: 12)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Blinking cursor
                      Row(
                        children: [
                          Text('${user.portfolioSlug.isNotEmpty ? user.portfolioSlug : 'user'}@codespotlight:~\$ ', style: GoogleFonts.firaCode(color: Colors.greenAccent)),
                          Container(width: 10, height: 20, color: Colors.greenAccent),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Prompt extends StatelessWidget {
  final String command;
  const _Prompt({required this.command});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.firaCode(fontSize: 16),
          children: [
            const TextSpan(text: 'guest@codespotlight:~\$ ', style: TextStyle(color: Colors.greenAccent)),
            TextSpan(text: command, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
