import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../models/project_model.dart';
import '../widgets/portfolio_templates/minimal_template.dart';
import '../widgets/portfolio_templates/grid_template.dart';
import '../widgets/portfolio_templates/terminal_template.dart';
import '../widgets/portfolio_templates/glassmorphic_template.dart';

class PortfolioEditorPage extends StatefulWidget {
  const PortfolioEditorPage({super.key});

  @override
  State<PortfolioEditorPage> createState() => _PortfolioEditorPageState();
}

class _PortfolioEditorPageState extends State<PortfolioEditorPage> {
  final _bioController = TextEditingController();
  final _avatarController = TextEditingController();
  final _slugController = TextEditingController();
  final _resumeController = TextEditingController();
  final _techController = TextEditingController();
  
  String _selectedTemplate = 'grid';
  bool _isPublished = false;
  bool _isLoading = true;
  bool _isSaving = false;

  List<String> _techStack = [];
  List<EducationItem> _education = [];
  List<ExperienceItem> _experiences = [];
  List<AchievementItem> _achievements = [];

  List<Project> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = AuthService.instance.user;
    if (user != null) {
      _bioController.text = user.bio;
      _avatarController.text = user.avatarUrl;
      _slugController.text = user.portfolioSlug;
      _resumeController.text = user.resumeUrl;
      _selectedTemplate = user.portfolioTemplate;
      _isPublished = user.portfolioPublished;
      
      _techStack = List.from(user.techStack);
      _education = List.from(user.education);
      _experiences = List.from(user.experiences);
      _achievements = List.from(user.achievements);
    }

    try {
      final projects = await ApiService.getProjects();
      setState(() {
        _projects = projects..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePortfolio() async {
    setState(() => _isSaving = true);
    try {
      final updatedUser = await ApiService.updatePortfolio(
        bio: _bioController.text.trim(),
        avatarUrl: _avatarController.text.trim(),
        portfolioTemplate: _selectedTemplate,
        portfolioPublished: _isPublished,
        resumeUrl: _resumeController.text.trim(),
        techStack: _techStack,
        education: _education,
        experiences: _experiences,
        achievements: _achievements,
      );

      AppUser finalUser = updatedUser;
      if (_slugController.text.trim() != updatedUser.portfolioSlug && _slugController.text.trim().isNotEmpty) {
        finalUser = await ApiService.claimSlug(_slugController.text.trim());
      }

      await AuthService.instance.updateUser(finalUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Portfolio updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<String?> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) {
      final bytes = await xfile.readAsBytes();
      final base64String = base64Encode(bytes);
      // Determine mime type from extension
      String mime = 'image/jpeg';
      if (xfile.name.toLowerCase().endsWith('.png')) mime = 'image/png';
      else if (xfile.name.toLowerCase().endsWith('.gif')) mime = 'image/gif';
      else if (xfile.name.toLowerCase().endsWith('.webp')) mime = 'image/webp';
      
      return 'data:$mime;base64,$base64String';
    }
    return null;
  }

  // Helper dialogs for lists
  Future<void> _editEducation([int? index]) async {
    final isNew = index == null;
    final item = isNew ? const EducationItem(heading: '', description: '', institution: '', dates: '') : _education[index];
    
    final hCtrl = TextEditingController(text: item.heading);
    final iCtrl = TextEditingController(text: item.institution);
    final dCtrl = TextEditingController(text: item.dates);
    final descCtrl = TextEditingController(text: item.description);

    final result = await showDialog<EducationItem>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceHigh,
        title: Text(isNew ? 'Add Education' : 'Edit Education', style: AppTheme.titleMedium),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: hCtrl, decoration: const InputDecoration(labelText: 'Degree / Heading')),
              const SizedBox(height: 8),
              TextField(controller: iCtrl, decoration: const InputDecoration(labelText: 'Institution')),
              const SizedBox(height: 8),
              TextField(controller: dCtrl, decoration: const InputDecoration(labelText: 'Dates (e.g. 2018 - 2022)')),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, EducationItem(
                heading: hCtrl.text,
                institution: iCtrl.text,
                dates: dCtrl.text,
                description: descCtrl.text,
              ));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        if (isNew) _education.add(result);
        else _education[index] = result;
      });
    }
  }

  Future<void> _editExperience([int? index]) async {
    final isNew = index == null;
    final item = isNew ? const ExperienceItem(role: '', company: '', dates: '', description: '') : _experiences[index];
    
    final rCtrl = TextEditingController(text: item.role);
    final cCtrl = TextEditingController(text: item.company);
    final dCtrl = TextEditingController(text: item.dates);
    final descCtrl = TextEditingController(text: item.description);
    String currentImg = item.imageUrl;

    final result = await showDialog<ExperienceItem>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: AppTheme.surfaceHigh,
          title: Text(isNew ? 'Add Experience' : 'Edit Experience', style: AppTheme.titleMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: rCtrl, decoration: const InputDecoration(labelText: 'Role')),
                const SizedBox(height: 8),
                TextField(controller: cCtrl, decoration: const InputDecoration(labelText: 'Company')),
                const SizedBox(height: 8),
                TextField(controller: dCtrl, decoration: const InputDecoration(labelText: 'Dates')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (currentImg.isNotEmpty)
                      Container(
                        width: 40, height: 40,
                        margin: const EdgeInsets.right(8),
                        decoration: BoxDecoration(
                          image: DecorationImage(image: currentImg.startsWith('data:') ? MemoryImage(base64Decode(currentImg.split(',')[1])) as ImageProvider : NetworkImage(currentImg), fit: BoxFit.cover),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(LucideIcons.imagePlus, size: 16),
                        label: Text(currentImg.isEmpty ? 'Add Image' : 'Change Image'),
                        onPressed: () async {
                          final img = await _pickImage();
                          if (img != null) {
                            setStateDialog(() => currentImg = img);
                          }
                        },
                      ),
                    ),
                    if (currentImg.isNotEmpty)
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 16, color: AppTheme.error),
                        onPressed: () => setStateDialog(() => currentImg = ''),
                      )
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx, ExperienceItem(
                  role: rCtrl.text,
                  company: cCtrl.text,
                  dates: dCtrl.text,
                  description: descCtrl.text,
                  imageUrl: currentImg,
                ));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (isNew) _experiences.add(result);
        else _experiences[index] = result;
      });
    }
  }

  Future<void> _editAchievement([int? index]) async {
    final isNew = index == null;
    final item = isNew ? const AchievementItem(title: '', description: '') : _achievements[index];
    
    final tCtrl = TextEditingController(text: item.title);
    final descCtrl = TextEditingController(text: item.description);
    String currentImg = item.imageUrl;

    final result = await showDialog<AchievementItem>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: AppTheme.surfaceHigh,
          title: Text(isNew ? 'Add Achievement' : 'Edit Achievement', style: AppTheme.titleMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: tCtrl, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (currentImg.isNotEmpty)
                      Container(
                        width: 40, height: 40,
                        margin: const EdgeInsets.right(8),
                        decoration: BoxDecoration(
                          image: DecorationImage(image: currentImg.startsWith('data:') ? MemoryImage(base64Decode(currentImg.split(',')[1])) as ImageProvider : NetworkImage(currentImg), fit: BoxFit.cover),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(LucideIcons.imagePlus, size: 16),
                        label: Text(currentImg.isEmpty ? 'Add Image' : 'Change Image'),
                        onPressed: () async {
                          final img = await _pickImage();
                          if (img != null) {
                            setStateDialog(() => currentImg = img);
                          }
                        },
                      ),
                    ),
                    if (currentImg.isNotEmpty)
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 16, color: AppTheme.error),
                        onPressed: () => setStateDialog(() => currentImg = ''),
                      )
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx, AchievementItem(
                  title: tCtrl.text,
                  description: descCtrl.text,
                  imageUrl: currentImg,
                ));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (isNew) _achievements.add(result);
        else _achievements[index] = result;
      });
    }
  }

  Widget _buildListSection<T>({
    required String title,
    required List<T> items,
    required Widget Function(T, int) builder,
    required VoidCallback onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTheme.headlineMedium),
            IconButton(
              icon: const Icon(LucideIcons.plusCircle, color: AppTheme.primary),
              onPressed: onAdd,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text('No items added yet.', style: AppTheme.bodySmall)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (ctx, i) => builder(items[i], i),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Portfolio Builder'),
        actions: [
          if (_isPublished)
            TextButton.icon(
              icon: const Icon(LucideIcons.externalLink, size: 16),
              label: const Text('View Live'),
              onPressed: () {
                if (_slugController.text.isNotEmpty) {
                  context.push('/p/${_slugController.text}');
                }
              },
            ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _savePortfolio,
            icon: _isSaving 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(LucideIcons.save, size: 16),
            label: const Text('Save'),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 1000;
          final editor = SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Publishing Status
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Make my portfolio public', style: AppTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text(
                                _isPublished 
                                    ? 'Anyone with the link can view your portfolio.' 
                                    : 'Only you can see your portfolio.',
                                style: AppTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isPublished,
                          onChanged: (v) => setState(() => _isPublished = v),
                          activeColor: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 2. Slug & URL
                  Text('Your URL', style: AppTheme.headlineMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppTheme.radiusChip),
                            bottomLeft: Radius.circular(AppTheme.radiusChip),
                          ),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text('codespotlight-hm.web.app/p/', style: AppTheme.bodyMedium),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _slugController,
                          decoration: const InputDecoration(
                            hintText: 'your-custom-slug',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(AppTheme.radiusChip),
                                bottomRight: Radius.circular(AppTheme.radiusChip),
                              ),
                            ),
                          ),
                          onChanged: (v) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 3. Profile Info
                  Text('Profile', style: AppTheme.headlineMedium),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            TextField(
                              controller: _avatarController,
                              decoration: const InputDecoration(labelText: 'Avatar URL'),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _resumeController,
                              decoration: const InputDecoration(labelText: 'Resume URL (Optional)'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        children: [
                          const Text('Or upload:'),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final img = await _pickImage();
                              if (img != null) {
                                setState(() {
                                  _avatarController.text = img;
                                });
                              }
                            },
                            icon: const Icon(LucideIcons.imagePlus, size: 16),
                            label: const Text('Device'),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bioController,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 4. Tech Stack
                  Text('Tech Stack', style: AppTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _techStack.map((tech) => Chip(
                      label: Text(tech),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => setState(() => _techStack.remove(tech)),
                      backgroundColor: AppTheme.surfaceLight,
                      side: const BorderSide(color: AppTheme.border),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _techController,
                          decoration: const InputDecoration(labelText: 'Add Technology (e.g. Flutter)'),
                          onSubmitted: (v) {
                            if (v.trim().isNotEmpty && !_techStack.contains(v.trim())) {
                              setState(() => _techStack.add(v.trim()));
                              _techController.clear();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(LucideIcons.plus, color: AppTheme.primary),
                        onPressed: () {
                          final v = _techController.text.trim();
                          if (v.isNotEmpty && !_techStack.contains(v)) {
                            setState(() => _techStack.add(v));
                            _techController.clear();
                          }
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 5. Dynamic Lists
                  _buildListSection<EducationItem>(
                    title: 'Education',
                    items: _education,
                    onAdd: () => _editEducation(),
                    builder: (item, index) => ListTile(
                      title: Text(item.heading, style: AppTheme.titleMedium),
                      subtitle: Text('${item.institution} • ${item.dates}', style: AppTheme.bodySmall),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(LucideIcons.edit2, size: 16), onPressed: () => _editEducation(index)),
                          IconButton(icon: const Icon(LucideIcons.trash2, size: 16, color: AppTheme.error), onPressed: () => setState(() => _education.removeAt(index))),
                        ],
                      ),
                    )
                  ),
                  const SizedBox(height: 24),
                  
                  _buildListSection<ExperienceItem>(
                    title: 'Experience',
                    items: _experiences,
                    onAdd: () => _editExperience(),
                    builder: (item, index) => ListTile(
                      leading: item.imageUrl.isNotEmpty 
                        ? Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              image: DecorationImage(image: item.imageUrl.startsWith('data:') ? MemoryImage(base64Decode(item.imageUrl.split(',')[1])) as ImageProvider : NetworkImage(item.imageUrl), fit: BoxFit.cover),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                        : const Icon(LucideIcons.briefcase, color: AppTheme.textMuted),
                      title: Text(item.role, style: AppTheme.titleMedium),
                      subtitle: Text('${item.company} • ${item.dates}', style: AppTheme.bodySmall),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(LucideIcons.edit2, size: 16), onPressed: () => _editExperience(index)),
                          IconButton(icon: const Icon(LucideIcons.trash2, size: 16, color: AppTheme.error), onPressed: () => setState(() => _experiences.removeAt(index))),
                        ],
                      ),
                    )
                  ),
                  const SizedBox(height: 24),

                  _buildListSection<AchievementItem>(
                    title: 'Achievements',
                    items: _achievements,
                    onAdd: () => _editAchievement(),
                    builder: (item, index) => ListTile(
                      leading: item.imageUrl.isNotEmpty 
                        ? Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              image: DecorationImage(image: item.imageUrl.startsWith('data:') ? MemoryImage(base64Decode(item.imageUrl.split(',')[1])) as ImageProvider : NetworkImage(item.imageUrl), fit: BoxFit.cover),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                        : const Icon(LucideIcons.award, color: AppTheme.textMuted),
                      title: Text(item.title, style: AppTheme.titleMedium),
                      subtitle: Text(item.description, style: AppTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(LucideIcons.edit2, size: 16), onPressed: () => _editAchievement(index)),
                          IconButton(icon: const Icon(LucideIcons.trash2, size: 16, color: AppTheme.error), onPressed: () => setState(() => _achievements.removeAt(index))),
                        ],
                      ),
                    )
                  ),
                  const SizedBox(height: 32),

                  // 6. Template Picker
                  Text('Template', style: AppTheme.headlineMedium),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 3,
                    children: [
                      _TemplateCard(
                        id: 'minimal',
                        title: 'Minimal',
                        desc: 'Clean and focused',
                        selected: _selectedTemplate == 'minimal',
                        onTap: () => setState(() => _selectedTemplate = 'minimal'),
                      ),
                      _TemplateCard(
                        id: 'grid',
                        title: 'Grid',
                        desc: 'Visual bento layout',
                        selected: _selectedTemplate == 'grid',
                        onTap: () => setState(() => _selectedTemplate = 'grid'),
                      ),
                      _TemplateCard(
                        id: 'terminal',
                        title: 'Terminal',
                        desc: 'Hacker aesthetic',
                        selected: _selectedTemplate == 'terminal',
                        onTap: () => setState(() => _selectedTemplate = 'terminal'),
                      ),
                      _TemplateCard(
                        id: 'glassmorphic',
                        title: 'Glassmorphic',
                        desc: 'Frosted glass panels',
                        selected: _selectedTemplate == 'glassmorphic',
                        onTap: () => setState(() => _selectedTemplate = 'glassmorphic'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );

          if (!isWide) {
            return editor;
          }

          final mockUser = AppUser(
            id: AuthService.instance.user?.id ?? 'live_preview',
            email: AuthService.instance.user?.email ?? '',
            name: AuthService.instance.user?.name ?? 'Your Name',
            socialLinks: AuthService.instance.user?.socialLinks ?? {},
            bio: _bioController.text,
            avatarUrl: _avatarController.text,
            portfolioTemplate: _selectedTemplate,
            portfolioPublished: _isPublished,
            portfolioSlug: _slugController.text,
            resumeUrl: _resumeController.text,
            techStack: _techStack,
            education: _education,
            experiences: _experiences,
            achievements: _achievements,
          );

          final stats = {
            'totalStars': _projects.fold<int>(0, (s, p) => s + p.stars),
            'totalForks': _projects.fold<int>(0, (s, p) => s + p.forks),
            'languages': <String, int>{},
          };

          Widget templateView;
          switch (_selectedTemplate) {
            case 'minimal': templateView = MinimalTemplate(user: mockUser, projects: _projects.where((p) => p.isPublicOnPortfolio).toList(), stats: stats); break;
            case 'terminal': templateView = TerminalTemplate(user: mockUser, projects: _projects.where((p) => p.isPublicOnPortfolio).toList(), stats: stats); break;
            case 'glassmorphic': templateView = GlassmorphicTemplate(user: mockUser, projects: _projects.where((p) => p.isPublicOnPortfolio).toList(), stats: stats); break;
            case 'grid':
            default: templateView = GridTemplate(user: mockUser, projects: _projects.where((p) => p.isPublicOnPortfolio).toList(), stats: stats); break;
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: AppTheme.border)),
                  ),
                  child: editor,
                ),
              ),
              Expanded(
                flex: 3,
                child: ClipRect(
                  child: IgnorePointer(
                    child: templateView,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final String id, title, desc;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.id, required this.title, required this.desc,
    required this.selected, required this.onTap,
  });

  Widget _buildPreview() {
    return const SizedBox(); // Removed complex preview code for brevity
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.1) : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: _buildPreview()),
            Container(height: 1, color: selected ? AppTheme.primary.withOpacity(0.5) : AppTheme.border),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: AppTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(desc, style: AppTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
