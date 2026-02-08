import 'package:cloud_firestore/cloud_firestore.dart';

class Song {
  final String? id;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final String duration;
  final String imageUrl;
  final String audioUrl;
  final bool isDefault;
  final String createdBy;
  final DateTime createdAt;

  Song({
    this.id,
    required this.title,
    required this.artist,
    this.album = '',
    this.genre = '',
    this.duration = '0:00',
    this.imageUrl = '',
    this.audioUrl = '',
    this.isDefault = false,
    this.createdBy = 'system',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Song.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Song(
      id: doc.id,
      title: data['title'] ?? '',
      artist: data['artist'] ?? '',
      album: data['album'] ?? '',
      genre: data['genre'] ?? '',
      duration: data['duration'] ?? '0:00',
      imageUrl: data['imageUrl'] ?? '',
      audioUrl: data['audioUrl'] ?? '',
      isDefault: data['isDefault'] ?? false,
      createdBy: data['createdBy'] ?? 'system',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'artist': artist,
      'album': album,
      'genre': genre,
      'duration': duration,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'isDefault': isDefault,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? genre,
    String? duration,
    String? imageUrl,
    String? audioUrl,
    bool? isDefault,
    String? createdBy,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      duration: duration ?? this.duration,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      isDefault: isDefault ?? this.isDefault,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt,
    );
  }

  static List<String> get genres => [
    'Pop', 'Rock', 'Hip Hop', 'R&B', 'Jazz', 'Clásica', 'Electrónica',
    'Reggaeton', 'Indie', 'Metal', 'Folk', 'Blues', 'Country', 'Otro',
  ];
}
