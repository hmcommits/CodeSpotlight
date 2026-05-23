import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';

class TerminalTemplate extends StatefulWidget {
  final AppUser user;
  final List<Project> projects;
  final Map<String, dynamic> stats;

  const TerminalTemplate({
    super.key,
    required this.user,
    required this.projects,
    required this.stats,
  });

  @override
  State<TerminalTemplate> createState() => _TerminalTemplateState();
}

class _TerminalTemplateState extends State<TerminalTemplate> {
  String _typedName = "";
  late Timer _timer;
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTypewriter();
  }

  void _startTypewriter() {
    final fullName = "> root@${widget.user.portfolioSlug.isEmpty ? 'portfolio' : widget.user.portfolioSlug}:~\$ ${widget.user.name}";
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_charIndex < fullName.length) {
        setState(() {
          _typedName += fullName[_charIndex];
          _charIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final terminalStyle = GoogleFonts.firaCode(
      color: const Color(0xFF00FF41),
      fontSize: 16,
    );
    final terminalMuted = GoogleFonts.firaCode(
      color: const Color(0xFF008F11),
      fontSize: 14,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Typewriter Header
            Row(
              children: [
                Text(_typedName, style: terminalStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold)),
                _CursorBlink(style: terminalStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            Text('INFO: ${widget.user.bio}', style: terminalStyle),
            const SizedBox(height: 16),
            Text('--------------------------------------------------', style: terminalMuted),
            const SizedBox(height: 16),
            
            // Stats
            Text('SYS.STATS {', style: terminalStyle),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('repositories: ${widget.stats['totalRepos']}', style: terminalStyle),
                  Text('stars: ${widget.stats['totalStars']}', style: terminalStyle),
                  Text('deployments: ${widget.stats['liveDeployments']}', style: terminalStyle),
                ],
              ),
            ),
            Text('}', style: terminalStyle),
            const SizedBox(height: 32),

            // Projects
            Text('\$ ls -la ./projects', style: terminalStyle.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            ...widget.projects.map((p) => _TerminalProjectBox(project: p, style: terminalStyle, muted: terminalMuted)),
          ],
        ),
      ),
    );
  }
}

class _CursorBlink extends StatefulWidget {
  final TextStyle style;
  const _CursorBlink({required this.style});

  @override
  State<_CursorBlink> createState() => _CursorBlinkState();
}

class _CursorBlinkState extends State<_CursorBlink> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Text('█', style: widget.style),
    );
  }
}

class _TerminalProjectBox extends StatelessWidget {
  final Project project;
  final TextStyle style;
  final TextStyle muted;

  const _TerminalProjectBox({required this.project, required this.style, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF00FF41)),
        color: Colors.black,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('[+] ${project.repo}${project.featured ? ' (*) ' : ''}', style: style.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(project.customDescription.isNotEmpty ? project.customDescription : project.description, style: style),
          const SizedBox(height: 8),
          Text('Lang: ${project.primaryLanguage} | Stars: ${project.stars}', style: muted),
        ],
      ),
    );
  }
}
