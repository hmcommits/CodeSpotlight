import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    super.dispose();
  }

  void _startDemo(BuildContext ctx) {
    AuthService.instance.startDemo();
    ctx.go('/app');
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w > 900;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          _AnimatedOrbs(controller: _orbCtrl),
          SingleChildScrollView(
            child: Column(
              children: [
                _Navbar(onDemo: () => _startDemo(context)),
                isWide
                    ? _HeroWide(onDemo: () => _startDemo(context))
                    : _HeroNarrow(onDemo: () => _startDemo(context)),
                const _FeaturesSection(),
                const _HowItWorksSection(),
                _CtaSection(onDemo: () => _startDemo(context)),
                const _Footer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Animated orb background â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _AnimatedOrbs extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedOrbs({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Stack(children: [
          _orb(size.width * 0.15, size.height * (0.1 + t * 0.15),
              200, const Color(0xFF6C63FF), 0.18),
          _orb(size.width * 0.75, size.height * (0.05 + (1 - t) * 0.12),
              260, const Color(0xFF00D9FF), 0.13),
          _orb(size.width * 0.5, size.height * (0.55 + t * 0.1),
              180, const Color(0xFF9C6CFF), 0.12),
          _orb(size.width * (0.85 + t * 0.05), size.height * 0.7,
              140, const Color(0xFF00D9FF), 0.1),
        ]);
      },
    );
  }

  Widget _orb(double x, double y, double r, Color c, double opacity) =>
      Positioned(
        left: x - r,
        top: y - r,
        child: Container(
          width: r * 2,
          height: r * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              c.withValues(alpha: opacity),
              c.withValues(alpha: 0),
            ]),
          ),
        ),
      );
}

// â”€â”€ Navbar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _Navbar extends StatelessWidget {
  final VoidCallback onDemo;
  const _Navbar({required this.onDemo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Row(children: [
        ShaderMask(
          shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
          child: Text('CodeSpotlight',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ),
        const Spacer(),
        TextButton(
          onPressed: onDemo,
          child: Text('Demo',
              style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary)),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => context.go('/login'),
          child: Text('Sign In',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary)),
        ),
        const SizedBox(width: 12),
        _GradientButton(
            label: 'Get Started',
            onTap: () => context.go('/register')),
      ]),
    );
  }
}

// â”€â”€ Hero (wide) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _HeroWide extends StatelessWidget {
  final VoidCallback onDemo;
  const _HeroWide({required this.onDemo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(80, 60, 80, 80),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 6, child: _HeroText(onDemo: onDemo)),
          const SizedBox(width: 60),
          Expanded(flex: 5, child: _MockCard()),
        ],
      ),
    );
  }
}

class _HeroNarrow extends StatelessWidget {
  final VoidCallback onDemo;
  const _HeroNarrow({required this.onDemo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
      child: Column(children: [
        _HeroText(onDemo: onDemo),
        const SizedBox(height: 40),
        _MockCard(),
      ]),
    );
  }
}

class _HeroText extends StatelessWidget {
  final VoidCallback onDemo;
  const _HeroText({required this.onDemo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.auto_awesome, size: 13, color: AppTheme.primary),
            const SizedBox(width: 6),
            Text('AI-Powered Developer Portfolio',
                style: AppTheme.labelSmall.copyWith(color: AppTheme.primary)),
          ]),
        ).animate().fadeIn(duration: 600.ms),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
          child: Text('Showcase Your\nCode. Brilliantly.',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -1.5)),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 700.ms)
            .slideY(begin: 0.15),
        const SizedBox(height: 20),
        Text(
          'Transform any GitHub repository into a stunning\nvisual case study with AI analysis, architecture\ndiagrams, and commit visualizations.',
          style: GoogleFonts.inter(
              fontSize: 17,
              color: AppTheme.textSecondary,
              height: 1.7),
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 600.ms),
        const SizedBox(height: 36),
        Row(children: [
          _GradientButton(
              label: 'Create Free Account',
              onTap: () => context.go('/register'),
              large: true),
          const SizedBox(width: 16),
          _OutlineButton(label: 'Try Demo Mode', onTap: onDemo),
        ])
            .animate()
            .fadeIn(delay: 600.ms, duration: 500.ms),
        const SizedBox(height: 32),
        Row(children: [
          _Stat(label: 'AI-Powered', icon: Icons.auto_awesome),
          const SizedBox(width: 24),
          _Stat(label: 'Instant Analysis', icon: Icons.bolt),
          const SizedBox(width: 24),
          _Stat(label: 'Free Forever', icon: Icons.favorite),
        ]).animate().fadeIn(delay: 800.ms),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Stat({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AppTheme.primary),
      const SizedBox(width: 6),
      Text(label,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
    ],
  );
}

// â”€â”€ Mock Project Card (hero decoration) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _MockCard extends StatefulWidget {
  @override
  State<_MockCard> createState() => _MockCardState();
}

class _MockCardState extends State<_MockCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _float = Tween(begin: -8.0, end: 8.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, child) => Transform.translate(
          offset: Offset(0, _float.value), child: child),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.2),
                blurRadius: 40,
                spreadRadius: -5),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 10, height: 10,
                decoration: const BoxDecoration(
                    color: AppTheme.secondary, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text('flutter / flutter',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const Spacer(),
            Icon(Icons.star_rounded, size: 14, color: AppTheme.warning),
            const SizedBox(width: 4),
            Text('163k',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.warning)),
          ]),
          const SizedBox(height: 8),
          Text('Flutter makes it easy and fast to build beautiful apps',
              style: AppTheme.bodySmall),
          const SizedBox(height: 16),
          _MockBar(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI Technical Deep Dive',
                  style: AppTheme.labelSmall.copyWith(color: AppTheme.primary)),
              const SizedBox(height: 6),
              Text('Flutter is Google\'s UI toolkit for building natively compiled applications for mobile, web, and desktop...',
                  style: AppTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 6, children: ['Flutter', 'Dart', 'Cross-platform']
              .map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                    ),
                    child: Text(t, style: AppTheme.labelSmall.copyWith(color: AppTheme.primary, fontSize: 10)),
                  ))
              .toList()),
        ]),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 800.ms).slideX(begin: 0.1);
  }
}

class _MockBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final langs = [
      (AppTheme.secondary, 0.55),
      (const Color(0xFFF7DF1E), 0.25),
      (const Color(0xFF3572A5), 0.2),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Row(children: langs
          .map((l) => Expanded(
                flex: (l.$2 * 100).toInt(),
                child: Container(height: 6, color: l.$1),
              ))
          .toList()),
    );
  }
}

// â”€â”€ Features Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  static const _features = [
    (Icons.psychology_rounded, 'AI Deep Dive',
        'Gemini 2.5 Flash generates a 3-paragraph technical case study explaining the architecture and hardest problems solved.'),
    (Icons.description_rounded, 'Markdown READMEs',
        'Instantly export your AI-generated project analysis to beautiful, fully-formatted Markdown ready for GitHub.'),
    (Icons.account_tree_rounded, 'Architecture Diagram',
        'Auto-generated Mermaid.js flowcharts visualize components, data flow, and system interactions.'),
    (Icons.grid_on_rounded, 'Commit Heatmap',
        'A real 52-week × 7-day contribution grid pulled live from GitHub shows proof of consistent effort.'),
    (Icons.bolt_rounded, 'Live Status Monitor',
        'Heartbeat checks ping your deployed URL and show a real-time live/down badge on every card.'),
    (Icons.explore_rounded, 'Public Discoverability',
        'Share a secure read-only link to your portfolio, complete with your social links, or browse the global developer feed.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 80),
      child: Column(children: [
        ShaderMask(
          shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
          child: Text('Everything You Need',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white)),
        ).animate().fadeIn(),
        const SizedBox(height: 8),
        Text('One platform. Every metric that matters.',
            style: AppTheme.bodyMedium.copyWith(fontSize: 16)),
        const SizedBox(height: 48),
        LayoutBuilder(builder: (ctx, constraints) {
          final cols = constraints.maxWidth > 700 ? 2 : 1;
          return Wrap(
            spacing: 20, runSpacing: 20,
            children: _features.asMap().entries.map((e) {
              final i = e.key; final f = e.value;
              return SizedBox(
                width: (constraints.maxWidth - (cols - 1) * 20) / cols,
                child: _FeatureCard(icon: f.$1, title: f.$2, desc: f.$3, index: i),
              );
            }).toList(),
          );
        }),
      ]),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  final int index;
  const _FeatureCard({required this.icon, required this.title,
      required this.desc, required this.index});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _hov ? AppTheme.surfaceHigh : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _hov
                  ? AppTheme.primary.withValues(alpha: 0.4)
                  : AppTheme.border),
          boxShadow: _hov
              ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.12),
                  blurRadius: 24)]
              : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.icon, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(height: 16),
          Text(widget.title,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 18, fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(widget.desc, style: AppTheme.bodyMedium),
        ]),
      ).animate(delay: (widget.index * 100).ms).fadeIn().slideY(begin: 0.1),
    );
  }
}

// â”€â”€ How It Works â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  static const _steps = [
    (Icons.link_rounded, 'Paste GitHub URL',
        'Drop any public GitHub repository URL into CodeSpotlight.'),
    (Icons.auto_awesome_rounded, 'AI Analyzes',
        'Gemini builds a deep-dive case study, architecture diagram, and a fully formatted README for you.'),
    (Icons.person_outline_rounded, 'Customize Profile',
        'Add your LinkedIn, Twitter, and portfolio links to establish your professional brand.'),
    (Icons.share_rounded, 'Share & Discover',
        'Get a secure, read-only link for recruiters, and optionally appear on the global developer discovery feed.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.04),
            AppTheme.secondary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.symmetric(
          horizontal: BorderSide(color: AppTheme.border),
        ),
      ),
      child: Column(children: [
        ShaderMask(
          shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
          child: Text('How It Works',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 36, fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ).animate().fadeIn(),
        const SizedBox(height: 48),
        LayoutBuilder(builder: (ctx, box) {
          final cols = box.maxWidth > 900 ? 4 : box.maxWidth > 600 ? 2 : 1;
          return Wrap(
            spacing: 24, runSpacing: 24,
            children: _steps.asMap().entries.map((e) {
              final i = e.key; final s = e.value;
              return SizedBox(
                width: (box.maxWidth - (cols - 1) * 24) / cols,
                child: _StepCard(n: i + 1, icon: s.$1,
                    title: s.$2, desc: s.$3, delay: i * 150),
              );
            }).toList(),
          );
        }),
      ]),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int n, delay;
  final IconData icon;
  final String title, desc;
  const _StepCard(
      {required this.n, required this.icon, required this.title,
       required this.desc, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 40, height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('$n',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ),
        const SizedBox(width: 16),
        Icon(icon, color: AppTheme.secondary, size: 22),
      ]),
      const SizedBox(height: 16),
      Text(title,
          style: GoogleFonts.spaceGrotesk(
              fontSize: 18, fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary)),
      const SizedBox(height: 8),
      Text(desc, style: AppTheme.bodyMedium),
    ]).animate(delay: delay.ms).fadeIn().slideY(begin: 0.1);
  }
}

// â”€â”€ Bottom CTA â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CtaSection extends StatelessWidget {
  final VoidCallback onDemo;
  const _CtaSection({required this.onDemo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      child: Column(children: [
        ShaderMask(
          shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
          child: Text('Ready to Shine?',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 42, fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ).animate().fadeIn(),
        const SizedBox(height: 12),
        Text('Start building your developer portfolio in under 60 seconds.',
            style: AppTheme.bodyMedium.copyWith(fontSize: 16)).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 32),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _GradientButton(
              label: 'Create Free Account',
              onTap: () => context.go('/register'),
              large: true),
          const SizedBox(width: 16),
          _OutlineButton(label: 'Explore Demo', onTap: onDemo),
        ]).animate().fadeIn(delay: 400.ms),
      ]),
    );
  }
}

// â”€â”€ Footer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border))),
      child: Row(children: [
        ShaderMask(
          shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
          child: Text('CodeSpotlight',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
        const Spacer(),
        Text('Â© 2026 â€” Built with Flutter & Gemini AI',
            style: AppTheme.bodySmall),
      ]),
    );
  }
}

// â”€â”€ Shared button widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool large;
  const _GradientButton(
      {required this.label, required this.onTap, this.large = false});

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
              horizontal: widget.large ? 28 : 20,
              vertical: widget.large ? 16 : 12),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: _hov
                ? [BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 20, spreadRadius: -4)]
                : [],
          ),
          child: Text(widget.label,
              style: GoogleFonts.inter(
                  fontSize: widget.large ? 15 : 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.onTap});

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: _hov ? AppTheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: _hov ? AppTheme.primary : AppTheme.border,
                width: 1.5),
          ),
          child: Text(widget.label,
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w500,
                  color: _hov ? AppTheme.primary : AppTheme.textPrimary)),
        ),
      ),
    );
  }
}

