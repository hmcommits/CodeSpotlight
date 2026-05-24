import 'dart:convert';

class AppUser {
  final String id;
  final String email;
  final String name;
  final Map<String, String> socialLinks;
  final String bio;
  final String avatarUrl;
  final String portfolioTemplate;
  final bool portfolioPublished;
  final String portfolioSlug;
  final String resumeUrl;
  final List<String> techStack;
  final List<EducationItem> education;
  final List<ExperienceItem> experiences;
  final List<AchievementItem> achievements;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.socialLinks = const {},
    this.bio = '',
    this.avatarUrl = '',
    this.portfolioTemplate = 'grid',
    this.portfolioPublished = false,
    this.portfolioSlug = '',
    this.resumeUrl = '',
    this.techStack = const [],
    this.education = const [],
    this.experiences = const [],
    this.achievements = const [],
  });

  /// Parses a User object from the backend.
  /// The API consistently returns { id, email, name, socialLinks } at the top level.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    Map<String, String> parsedLinks = {};
    if (json['socialLinks'] is Map) {
      final map = json['socialLinks'] as Map;
      for (final k in map.keys) {
        final v = map[k]?.toString() ?? '';
        if (v.isNotEmpty) parsedLinks[k.toString()] = v;
      }
    }

    return AppUser(
      id:          json['id']?.toString() ?? json['_id']?.toString() ?? '',
      email:       json['email'] as String? ?? '',
      name:        json['name'] as String? ?? '',
      socialLinks: parsedLinks,
      bio:         json['bio'] as String? ?? '',
      avatarUrl:   json['avatarUrl'] as String? ?? '',
      portfolioTemplate: json['portfolioTemplate'] as String? ?? 'grid',
      portfolioPublished: json['portfolioPublished'] as bool? ?? false,
      portfolioSlug: json['portfolioSlug'] as String? ?? '',
      resumeUrl: json['resumeUrl'] as String? ?? '',
      techStack: (json['techStack'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      education: (json['education'] as List<dynamic>?)?.map((e) => EducationItem.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      experiences: (json['experiences'] as List<dynamic>?)?.map((e) => ExperienceItem.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      achievements: (json['achievements'] as List<dynamic>?)?.map((e) => AchievementItem.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'socialLinks': socialLinks,
    'bio': bio,
    'avatarUrl': avatarUrl,
    'portfolioTemplate': portfolioTemplate,
    'portfolioPublished': portfolioPublished,
    'portfolioSlug': portfolioSlug,
    'resumeUrl': resumeUrl,
    'techStack': techStack,
    'education': education.map((e) => e.toJson()).toList(),
    'experiences': experiences.map((e) => e.toJson()).toList(),
    'achievements': achievements.map((e) => e.toJson()).toList(),
  };

  String toJsonString() => jsonEncode(toJson());

  static AppUser fromJsonString(String s) =>
      AppUser.fromJson(jsonDecode(s) as Map<String, dynamic>);

  /// Display initial for avatar
  String get initial => name.isNotEmpty
      ? name[0].toUpperCase()
      : email.isNotEmpty ? email[0].toUpperCase() : 'U';

  AppUser copyWith({
    String? name,
    Map<String, String>? socialLinks,
    String? bio,
    String? avatarUrl,
    String? portfolioTemplate,
    bool? portfolioPublished,
    String? portfolioSlug,
    String? resumeUrl,
    List<String>? techStack,
    List<EducationItem>? education,
    List<ExperienceItem>? experiences,
    List<AchievementItem>? achievements,
  }) {
    return AppUser(
      id: id,
      email: email,
      name: name ?? this.name,
      socialLinks: socialLinks ?? this.socialLinks,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      portfolioTemplate: portfolioTemplate ?? this.portfolioTemplate,
      portfolioPublished: portfolioPublished ?? this.portfolioPublished,
      portfolioSlug: portfolioSlug ?? this.portfolioSlug,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      techStack: techStack ?? this.techStack,
      education: education ?? this.education,
      experiences: experiences ?? this.experiences,
      achievements: achievements ?? this.achievements,
    );
  }
}

class EducationItem {
  final String heading;
  final String description;
  final String institution;
  final String dates;

  const EducationItem({
    required this.heading,
    required this.description,
    required this.institution,
    required this.dates,
  });

  factory EducationItem.fromJson(Map<String, dynamic> json) => EducationItem(
    heading: json['heading']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    institution: json['institution']?.toString() ?? '',
    dates: json['dates']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'heading': heading,
    'description': description,
    'institution': institution,
    'dates': dates,
  };
}

class ExperienceItem {
  final String role;
  final String company;
  final String dates;
  final String description;
  final String imageUrl;

  const ExperienceItem({
    required this.role,
    required this.company,
    required this.dates,
    required this.description,
    this.imageUrl = '',
  });

  factory ExperienceItem.fromJson(Map<String, dynamic> json) => ExperienceItem(
    role: json['role']?.toString() ?? '',
    company: json['company']?.toString() ?? '',
    dates: json['dates']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    imageUrl: json['imageUrl']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'role': role,
    'company': company,
    'dates': dates,
    'description': description,
    'imageUrl': imageUrl,
  };
}

class AchievementItem {
  final String title;
  final String description;
  final String imageUrl;

  const AchievementItem({
    required this.title,
    required this.description,
    this.imageUrl = '',
  });

  factory AchievementItem.fromJson(Map<String, dynamic> json) => AchievementItem(
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    imageUrl: json['imageUrl']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
  };
}
