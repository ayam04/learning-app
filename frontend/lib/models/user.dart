class User {
  final String id;
  final DateTime? createdAt;

  User({required this.id, this.createdAt});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['user_id'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'created_at': createdAt?.toIso8601String()};
}
