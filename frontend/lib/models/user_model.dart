import 'dart:convert';

class AppUser {
  final String id;
  final String email;
  final String name;

  const AppUser({required this.id, required this.email, required this.name});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id:    json['id']    as String? ?? '',
        email: json['email'] as String? ?? '',
        name:  json['name']  as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'name': name};

  String toJsonString() => jsonEncode(toJson());
  static AppUser fromJsonString(String s) => AppUser.fromJson(jsonDecode(s) as Map<String, dynamic>);

  /// Display initial for avatar
  String get initial => name.isNotEmpty ? name[0].toUpperCase()
      : email.isNotEmpty ? email[0].toUpperCase() : 'U';
}
