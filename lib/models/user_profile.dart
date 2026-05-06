class UserProfile {
  final String id;
  final String displayName;
  final String email;
  final String imageUrl;
  final int followersCount;
  final int followingCount;

  UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.imageUrl = '',
    this.followersCount = 0,
    this.followingCount = 0,
  });

  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      displayName: data['displayName'] ?? 'Usuario',
      email: data['email'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
    );
  }
}
