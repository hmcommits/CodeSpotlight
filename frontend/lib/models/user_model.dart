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

  factory AppUser.fromJson(Map<String, dynamic> json) {
    // Parse socialLinks safely
    Map<String, String> parsedLinks = {};
    if (json['socialLinks'] is Map) {
      final map = json['socialLinks'] as Map;
      for (var k in map.keys) {
        if (map[k] != null && map[k]!.toString().isNotEmpty) {
          parsedLinks[k.toString()] = map[k].toString();
        }
      }
    } else if (json['user'] != null && json['user']['socialLinks'] is Map) {
      // In case data comes nested from some endpoints
      final map = json['user']['socialLinks'] as Map;
      for (var k in map.keys) {
        if (map[k] != null && map[k]!.toString().isNotEmpty) {
          parsedLinks[k.toString()] = map[k].toString();
        }
      }
    }

    return AppUser(
      id:    json['id']    as String? ?? json['_id'] as String? ?? (json['user']?['_id'] as String?) ?? '',
      email: json['email'] as String? ?? (json['user']?['email'] as String?) ?? '',
      name:  json['name']  as String? ?? (json['user']?['name'] as String?) ?? '',
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
  static AppUser fromJsonString(String s) => AppUser.fromJson(jsonDecode(s) as Map<String, dynamic>);

  /// Display initial for avatar
  String get initial => name.isNotEmpty ? name[0].toUpperCase()
      : email.isNotEmpty ? email[0].toUpperCase() : 'U';
}
