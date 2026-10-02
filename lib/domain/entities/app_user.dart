// el usuario con sesion
class AppUser {
  const AppUser({required this.id, required this.email, required this.name});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    email: json['email'] as String,
    name: json['name'] as String? ?? '',
  );

  final String id;
  final String email;

  // el backend manda "" si no puso nombre
  final String name;

  String get displayName => name.isEmpty ? email.split('@').first : name;

  String get initials {
    final words = displayName.trim().split(RegExp(r'\s+'));
    final letters = words.take(2).map((w) => w.isEmpty ? '' : w[0]).join();
    return letters.toUpperCase();
  }

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'name': name};
}
