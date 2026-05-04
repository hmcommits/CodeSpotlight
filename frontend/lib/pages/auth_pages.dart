import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.instance.login(
          _emailCtrl.text.trim(), _passCtrl.text, ApiService.baseUrl);
      if (mounted) context.go('/app');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startDemo() {
    AuthService.instance.startDemo();
    context.go('/app');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(children: [
        _Orbs(),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(children: [
                // Logo
                ShaderMask(
                  shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                  child: Text('CodeSpotlight',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 26, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ).animate().fadeIn(),
                const SizedBox(height: 8),
                Text('Welcome back',
                    style: AppTheme.bodyMedium).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 32),

                // Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          blurRadius: 40)
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Sign In',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 22, fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 24),

                      if (_error != null) ...[
                        _ErrorBanner(message: _error!),
                        const SizedBox(height: 16),
                      ],

                      _Field(
                        controller: _emailCtrl,
                        label: 'Email',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v?.contains('@') ?? false)
                            ? null : 'Enter a valid email',
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        controller: _passCtrl,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                              _obscure ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18, color: AppTheme.textMuted),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        validator: (v) => (v?.isNotEmpty ?? false)
                            ? null : 'Password is required',
                      ),
                      const SizedBox(height: 24),

                      _SubmitButton(
                          label: 'Sign In',
                          loading: _loading,
                          onTap: _login),

                      const SizedBox(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text("Don't have an account? ",
                            style: AppTheme.bodySmall),
                        GestureDetector(
                          onTap: () => context.go('/register'),
                          child: Text('Create one',
                              style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ]),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('or ', style: AppTheme.bodySmall),
                  GestureDetector(
                    onTap: _startDemo,
                    child: Text('continue in Demo Mode',
                        style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w500)),
                  ),
                ]).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => context.go('/'),
                  child: Text('← Back to home',
                      style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textMuted)),
                ).animate().fadeIn(delay: 500.ms),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Register Page ─────────────────────────────────────────────────────────────
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.instance.register(
          _nameCtrl.text.trim(),
          _emailCtrl.text.trim(),
          _passCtrl.text,
          ApiService.baseUrl);
      if (mounted) context.go('/app');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startDemo() {
    AuthService.instance.startDemo();
    context.go('/app');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(children: [
        _Orbs(),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(children: [
                ShaderMask(
                  shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                  child: Text('CodeSpotlight',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 26, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ).animate().fadeIn(),
                const SizedBox(height: 8),
                Text('Create your free account',
                    style: AppTheme.bodyMedium).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          blurRadius: 40)
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Get Started',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 22, fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 24),

                      if (_error != null) ...[
                        _ErrorBanner(message: _error!),
                        const SizedBox(height: 16),
                      ],

                      _Field(
                        controller: _nameCtrl,
                        label: 'Full Name',
                        icon: Icons.person_outline_rounded,
                        validator: (v) => (v?.isNotEmpty ?? false)
                            ? null : 'Name is required',
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        controller: _emailCtrl,
                        label: 'Email',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v?.contains('@') ?? false)
                            ? null : 'Enter a valid email',
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        controller: _passCtrl,
                        label: 'Password (min. 6 characters)',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                              _obscure ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18, color: AppTheme.textMuted),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        validator: (v) => (v != null && v.length >= 6)
                            ? null : 'At least 6 characters',
                      ),
                      const SizedBox(height: 24),

                      _SubmitButton(
                          label: 'Create Account',
                          loading: _loading,
                          onTap: _register),

                      const SizedBox(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Already have an account? ',
                            style: AppTheme.bodySmall),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text('Sign in',
                              style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ]),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('or ', style: AppTheme.bodySmall),
                  GestureDetector(
                    onTap: _startDemo,
                    child: Text('try Demo Mode first',
                        style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w500)),
                  ),
                ]).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => context.go('/'),
                  child: Text('← Back to home',
                      style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textMuted)),
                ).animate().fadeIn(delay: 500.ms),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Orbs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned(top: -80, left: -80,
          child: _orb(300, AppTheme.primary, 0.1)),
      Positioned(bottom: -60, right: -60,
          child: _orb(260, AppTheme.secondary, 0.08)),
    ]);
  }

  Widget _orb(double r, Color c, double op) => Container(
    width: r, height: r,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
          colors: [c.withValues(alpha: op), c.withValues(alpha: 0)]),
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
        prefixIcon: Icon(icon, size: 18, color: AppTheme.textMuted),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppTheme.surfaceHigh,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.error)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.error_outline, size: 16, color: AppTheme.error),
        const SizedBox(width: 8),
        Expanded(child: Text(message,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.error))),
      ]),
    );
  }
}

class _SubmitButton extends StatefulWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _SubmitButton(
      {required this.label, required this.loading, required this.onTap});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.loading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hov
                ? [BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 20, spreadRadius: -4)]
                : [],
          ),
          child: widget.loading
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(widget.label,
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: Colors.white)),
        ),
      ),
    );
  }
}
