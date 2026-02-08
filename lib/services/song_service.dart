import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/song.dart';

class SongService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _collection = 'songs';

  Stream<List<Song>> getSongs() {
    return _firestore.collection(_collection).orderBy('title').snapshots()
        .map((s) => s.docs.map((d) => Song.fromFirestore(d)).toList());
  }

  Future<List<Song>> getSongsList() async {
    final snapshot = await _firestore.collection(_collection).orderBy('title').get();
    return snapshot.docs.map((d) => Song.fromFirestore(d)).toList();
  }

  Future<List<Song>> getSongsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final songs = <Song>[];
    for (final id in ids) {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) songs.add(Song.fromFirestore(doc));
    }
    return songs;
  }

  Future<String> addSong(Song song) async {
    final docRef = await _firestore.collection(_collection).add(song.toFirestore());
    return docRef.id;
  }

  Future<void> updateSong(Song song) async {
    if (song.id == null) throw Exception('Song ID required');
    await _firestore.collection(_collection).doc(song.id).update(song.toFirestore());
  }

  Future<bool> deleteSong(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return false;
    final song = Song.fromFirestore(doc);
    if (song.isDefault) return false;
    
    if (song.imageUrl.isNotEmpty && song.imageUrl.contains('firebase')) {
      try { await _storage.refFromURL(song.imageUrl).delete(); } catch (_) {}
    }
    if (song.audioUrl.isNotEmpty && song.audioUrl.contains('firebase')) {
      try { await _storage.refFromURL(song.audioUrl).delete(); } catch (_) {}
    }
    
    await _firestore.collection(_collection).doc(id).delete();
    return true;
  }

  Future<String> uploadImage(File file) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('song_images/$name');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<String> uploadAudio(File file) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}.mp3';
    final ref = _storage.ref().child('song_audio/$name');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> seedDefaultSongs() async {
    final snapshot = await _firestore.collection(_collection).where('isDefault', isEqualTo: true).limit(1).get();
    if (snapshot.docs.isNotEmpty) return;
    final defaults = [
      Song(
        title: 'Bohemian Rhapsody', 
        artist: 'Queen', 
        album: 'A Night at the Opera', 
        genre: 'Rock', 
        duration: '5:55', 
        isDefault: true, 
        imageUrl: 'https://upload.wikimedia.org/wikipedia/en/9/9f/Bohemian_Rhapsody.png',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      ),
      Song(
        title: 'Hotel California', 
        artist: 'Eagles', 
        album: 'Hotel California', 
        genre: 'Rock', 
        duration: '6:30', 
        isDefault: true, 
        imageUrl: 'https://upload.wikimedia.org/wikipedia/en/4/49/Hotelcalifornia.jpg',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      ),
      Song(
        title: 'Billie Jean', 
        artist: 'Michael Jackson', 
        album: 'Thriller', 
        genre: 'Pop', 
        duration: '4:54', 
        isDefault: true, 
        imageUrl: 'https://upload.wikimedia.org/wikipedia/en/5/55/Michael_Jackson_-_Thriller.png',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      ),
      Song(
        title: 'Smells Like Teen Spirit', 
        artist: 'Nirvana', 
        album: 'Nevermind', 
        genre: 'Rock', 
        duration: '5:01', 
        isDefault: true, 
        imageUrl: 'https://upload.wikimedia.org/wikipedia/en/b/b7/NirvanaNevermindalbumcover.jpg',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      ),
      Song(
        title: 'Shape of You', 
        artist: 'Ed Sheeran', 
        album: '÷', 
        genre: 'Pop', 
        duration: '3:53', 
        isDefault: true, 
        imageUrl: 'https://upload.wikimedia.org/wikipedia/en/b/b4/Shape_Of_You_%28Official_Single_Cover%29_by_Ed_Sheeran.png',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
      ),
      Song(
        title: 'Blinding Lights', 
        artist: 'The Weeknd', 
        album: 'After Hours', 
        genre: 'Pop', 
        duration: '3:20', 
        isDefault: true, 
        imageUrl: 'https://upload.wikimedia.org/wikipedia/en/e/e6/The_Weeknd_-_Blinding_Lights.png',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
      ),
      Song(
        title: 'Stairway to Heaven', 
        artist: 'Led Zeppelin', 
        album: 'Led Zeppelin IV', 
        genre: 'Rock', 
        duration: '8:02', 
        isDefault: true, 
        imageUrl: 'https://upload.wikimedia.org/wikipedia/en/2/26/Led_Zeppelin_-_Led_Zeppelin_IV.jpg',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
      ),
      Song(
        title: 'Imagine', 
        artist: 'John Lennon', 
        album: 'Imagine', 
        genre: 'Pop', 
        duration: '3:07', 
        isDefault: true, 
        imageUrl: 'https://upload.wikimedia.org/wikipedia/en/6/69/ImijohnL.jpg',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
      ),
    ];
    for (final song in defaults) {
      await addSong(song);
    }
  }
}
