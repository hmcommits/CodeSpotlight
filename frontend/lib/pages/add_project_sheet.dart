import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';

class AddProjectSheet extends StatefulWidget {
  final void Function(Project project) onProjectAdded;

  const AddProjectSheet({super.key, required this.onProjectAdded});

  @override
  State<AddProjectSheet> createState() => _AddProjectSheetState();
}

class _AddProjectSheetState extends State<AddProjectSheet> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _liveUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();

  bool _loading = false;
  String _step = '';
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    _liveUrlController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
      _step = 'Fetching repository metadata...';
    });

    try {
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => _step = 'Extracting file structure...');
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() => _step = 'Queuing AI analysis...');

      final project = await ApiService.submitProject(
        _urlController.text.trim(),
        liveUrl: _liveUrlController.text.trim(),
        videoUrl: _videoUrlController.text.trim(),
      );

      setState(() => _step = 'Done! AI is analyzing in the background ✨');
      await Future.delayed(const Duration(milliseconds: 800));

      widget.onProjectAdded(project);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
        _step = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text('Add a Repository', style: AppTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Paste a public GitHub repo URL — we\'ll do the rest.',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            // GitHub URL
            TextFormField(
              controller: _urlController,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'https://github.com/owner/repo',
                prefixIcon: Icon(Icons.link_rounded, size: 18),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'GitHub URL is required';
                if (!v.trim().startsWith('https://github.com/')) {
                  return 'Must be a valid https://github.com/... URL';
                }
                return null;
              },
              enabled: !_loading,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),

            // Live URL (optional)
            TextFormField(
              controller: _liveUrlController,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'https://yourapp.com (optional)',
                prefixIcon: Icon(Icons.rocket_launch_rounded, size: 18),
              ),
              enabled: !_loading,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),

            // Video URL (optional)
            TextFormField(
              controller: _videoUrlController,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Demo video URL (optional)',
                prefixIcon: Icon(Icons.play_circle_outline_rounded, size: 18),
              ),
              enabled: !_loading,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 20),

            // Error
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.error),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

            // Progress step
            if (_loading && _step.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _step,
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(_loading ? 'Analyzing...' : 'Analyze Repository'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
