import 'package:cloud_firestore/cloud_firestore.dart';

class Playlist {
  final String? id;
  final String name;
  final String description;
  final String imageUrl;
  final String userId;
  final List<String> songIds;
  final DateTime createdAt;
  
  int get songCount => songIds.length;

  Playlist({
    this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    required this.userId,
    this.songIds = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Playlist.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Playlist(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      userId: data['userId'] ?? '',
      songIds: List<String>.from(data['songIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'userId': userId,
      'songIds': songIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? userId,
    List<String>? songIds,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId ?? this.userId,
      songIds: songIds ?? this.songIds,
      createdAt: createdAt,
    );
  }
}
