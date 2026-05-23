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
  };

  String toJsonString() => jsonEncode(toJson());

  static AppUser fromJsonString(String s) =>
      AppUser.fromJson(jsonDecode(s) as Map<String, dynamic>);

  /// Display initial for avatar
  String get initial => name.isNotEmpty
      ? name[0].toUpperCase()
      : email.isNotEmpty ? email[0].toUpperCase() : 'U';
}
