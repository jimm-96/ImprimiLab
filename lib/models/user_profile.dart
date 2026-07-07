class UserProfile {
  final String id;
  final String username;
  final String passwordHash;
  final String name;
  final String email;
  final String? phone;
  final String? workshopName;
  final String? bio;
  final String? website;
  final String? makerLevel;

  UserProfile({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.name,
    required this.email,
    this.phone,
    this.workshopName,
    this.bio,
    this.website,
    this.makerLevel,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      passwordHash: json['passwordHash'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      workshopName: json['workshopName'] as String?,
      bio: json['bio'] as String?,
      website: json['website'] as String?,
      makerLevel: json['makerLevel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'passwordHash': passwordHash,
      'name': name,
      'email': email,
      'phone': phone,
      'workshopName': workshopName,
      'bio': bio,
      'website': website,
      'makerLevel': makerLevel,
    };
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? passwordHash,
    String? name,
    String? email,
    String? phone,
    String? workshopName,
    String? bio,
    String? website,
    String? makerLevel,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      workshopName: workshopName ?? this.workshopName,
      bio: bio ?? this.bio,
      website: website ?? this.website,
      makerLevel: makerLevel ?? this.makerLevel,
    );
  }
}
