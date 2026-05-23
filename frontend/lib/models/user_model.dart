import 'dart:convert';

class AppUser {
  final String id;
  final String email;
  final String name;
  final Map<String, String> socialLinks;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.socialLinks = const {},
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
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'socialLinks': socialLinks,
  };

  String toJsonString() => jsonEncode(toJson());

  static AppUser fromJsonString(String s) =>
      AppUser.fromJson(jsonDecode(s) as Map<String, dynamic>);

  /// Display initial for avatar
  String get initial => name.isNotEmpty
      ? name[0].toUpperCase()
      : email.isNotEmpty ? email[0].toUpperCase() : 'U';
}
