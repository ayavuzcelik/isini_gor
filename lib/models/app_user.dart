/// Google ile giriş yapan kullanıcı.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.phone,
  });

  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? phone;

  /// Avatar için baş harfler (fotoğraf yoksa).
  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return _firstLetter(parts.first);
    return _firstLetter(parts.first) + _firstLetter(parts.last);
  }

  static String _firstLetter(String value) =>
      value.isEmpty ? '' : value.substring(0, 1).toUpperCase();

  AppUser copyWith({String? phone}) => AppUser(
    id: id,
    name: name,
    email: email,
    photoUrl: photoUrl,
    phone: phone ?? this.phone,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'photoUrl': photoUrl,
    'phone': phone,
  };

  factory AppUser.fromMap(String id, Map<String, dynamic> map) => AppUser(
    id: id,
    name: map['name'] as String? ?? '',
    email: map['email'] as String? ?? '',
    photoUrl: map['photoUrl'] as String?,
    phone: map['phone'] as String?,
  );
}
