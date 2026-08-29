import 'package:appwrite/models.dart' as models;

/// Application profile mirroring `hari_om_db.users` collection.
/// Linked to Appwrite Auth via `userId == models.User.$id`.
class UserModel {
  const UserModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = 'customer',
    this.privileges = const [],
    this.status = 'active',
    this.emailVerification = false,
    this.phoneVerification = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id; // document $id
  final String userId; // Appwrite auth $id
  final String name;
  final String email;
  final String phone;
  final String role;
  final List<String> privileges;
  final String status;
  final bool emailVerification;
  final bool phoneVerification;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => role == 'admin';
  bool get isActive => status == 'active';

  factory UserModel.fromDocument(models.Document doc) {
    final d = doc.data;
    return UserModel(
      id: doc.$id,
      userId: (d['userId'] ?? d['user_id'] ?? doc.$id).toString(),
      name: (d['name'] ?? '').toString(),
      email: (d['email'] ?? '').toString().toLowerCase(),
      phone: (d['phone'] ?? '').toString(),
      role: (d['role'] ?? 'customer').toString(),
      privileges: _parsePrivileges(d['privileges']),
      status: (d['status'] ?? 'active').toString(),
      emailVerification: d['emailVerification'] == true || d['email_verification'] == true,
      phoneVerification: d['phoneVerification'] == true || d['phone_verification'] == true,
      createdAt: DateTime.tryParse(doc.$createdAt),
      updatedAt: DateTime.tryParse(doc.$updatedAt),
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> m) {
    return UserModel(
      id: (m['\$id'] ?? m['id'] ?? m['userId'] ?? '').toString(),
      userId: (m['userId'] ?? m['user_id'] ?? m['\$id'] ?? '').toString(),
      name: (m['name'] ?? '').toString(),
      email: (m['email'] ?? '').toString(),
      phone: (m['phone'] ?? '').toString(),
      role: (m['role'] ?? 'customer').toString(),
      privileges: _parsePrivileges(m['privileges']),
      status: (m['status'] ?? 'active').toString(),
      emailVerification: m['emailVerification'] == true || m['email_verification'] == true,
      phoneVerification: m['phoneVerification'] == true || m['phone_verification'] == true,
      createdAt: m['\$createdAt'] != null ? DateTime.tryParse(m['\$createdAt'].toString()) : null,
      updatedAt: m['\$updatedAt'] != null ? DateTime.tryParse(m['\$updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'email': email.toLowerCase(),
        'phone': phone,
        'role': role,
        'privileges': privilegesToString(privileges),
        'status': status,
        'emailVerification': emailVerification,
        'phoneVerification': phoneVerification,
      };

  UserModel copyWith({
    String? name,
    String? phone,
    String? role,
    List<String>? privileges,
    String? status,
    bool? emailVerification,
    bool? phoneVerification,
  }) =>
      UserModel(
        id: id,
        userId: userId,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        privileges: privileges ?? this.privileges,
        status: status ?? this.status,
        emailVerification: emailVerification ?? this.emailVerification,
        phoneVerification: phoneVerification ?? this.phoneVerification,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static List<String> _parsePrivileges(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    final s = raw.toString().trim();
    if (s.isEmpty || s == '[]') return [];
    final cleaned = s.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').replaceAll("'", '');
    return cleaned.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  static String privilegesToString(List<String> list) {
    if (list.isEmpty) return '[]';
    return '[${list.map((e) => '"$e"').join(',')}]';
  }

  @override
  String toString() => 'UserModel($email, role:$role, status:$status)';
}
