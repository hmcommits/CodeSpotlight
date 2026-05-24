import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../mock/portfolio_mock.dart';
import '../../theme/app_theme.dart';
import '../widgets/portfolio_templates/minimal_template.dart';
import '../widgets/portfolio_templates/grid_template.dart';
import '../widgets/portfolio_templates/terminal_template.dart';
import '../widgets/portfolio_templates/glassmorphic_template.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PortfolioPage extends StatefulWidget {
  final String slug;
  const PortfolioPage({super.key, required this.slug});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  bool _loading = true;
  String? _error;
  AppUser? _user;
  List<Project> _projects = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (PortfolioMock.kUseMock) {
        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 600));
        final data = PortfolioMock.getPortfolioMock();
        
        // Mock user slug matching check isn't strict, but if user specifically tested
        // "mockdev", it would work. Otherwise we just render the mock data.
        
        _user = data['user'] as AppUser;
        _projects = data['projects'] as List<Project>;
        _stats = data['stats'] as Map<String, dynamic>;

        if (!(_user?.portfolioPublished ?? false)) {
           _error = 'This portfolio is private.';
           _user = null;
        }

      } else {
        final data = await ApiService.getPortfolioBySlug(widget.slug);
        _user = data['user'] as AppUser;
        _projects = data['projects'] as List<Project>;
        _stats = data['stats'] as Map<String, dynamic>;
      }
    } catch (e) {
      _error = 'Portfolio not found or is private.';
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_error != null || _user == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.shieldAlert, size: 64, color: AppTheme.textMuted),
              const SizedBox(height: 24),
              Text(
                '404 / Private',
                style: AppTheme.displayLarge,
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'This portfolio does not exist or is not public.',
                style: AppTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Render appropriate template
    switch (_user!.portfolioTemplate) {
      case 'minimal':
        return MinimalTemplate(user: _user!, projects: _projects, stats: _stats);
      case 'terminal':
        return TerminalTemplate(user: _user!, projects: _projects, stats: _stats);
      case 'glassmorphic':
        return GlassmorphicTemplate(user: _user!, projects: _projects, stats: _stats);
      case 'grid':
      default:
        return GridTemplate(user: _user!, projects: _projects, stats: _stats);
    }
  }
}
