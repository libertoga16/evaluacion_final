import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
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
    print('SEEDING: Smart check for default songs...');

    final defaults = [
      Song(
        title: 'Bohemian Rhapsody', 
        artist: 'Queen', 
        album: 'A Night at the Opera', 
        genre: 'Rock', 
        duration: '5:55', 
        isDefault: true, 
        imageUrl: 'defaults/queen.jpg', // Will be resolved
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      ),
      Song(
        title: 'Hotel California', 
        artist: 'Eagles', 
        album: 'Hotel California', 
        genre: 'Rock', 
        duration: '6:30', 
        isDefault: true, 
        imageUrl: 'defaults/eagles.jpg',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      ),
      Song(
        title: 'Billie Jean', 
        artist: 'Michael Jackson', 
        album: 'Thriller', 
        genre: 'Pop', 
        duration: '4:54', 
        isDefault: true, 
        imageUrl: 'defaults/michael_janson.jpg',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      ),
      Song(
        title: 'Smells Like Teen Spirit', 
        artist: 'Nirvana', 
        album: 'Nevermind', 
        genre: 'Rock', 
        duration: '5:01', 
        isDefault: true, 
        imageUrl: 'defaults/Nirvana.jpg',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      ),
      Song(
        title: 'Shape of You', 
        artist: 'Ed Sheeran', 
        album: '÷', 
        genre: 'Pop', 
        duration: '3:53', 
        isDefault: true, 
        imageUrl: 'defaults/ed_Sheeran.jpg',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
      ),
      Song(
        title: 'Blinding Lights', 
        artist: 'The Weeknd', 
        album: 'After Hours', 
        genre: 'Pop', 
        duration: '3:20', 
        isDefault: true, 
        imageUrl: 'defaults/the_weeknd.jpg',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
      ),
      Song(
        title: 'Stairway to Heaven', 
        artist: 'Led Zeppelin', 
        album: 'Led Zeppelin IV', 
        genre: 'Rock', 
        duration: '8:02', 
        isDefault: true, 
        imageUrl: 'defaults/Leed_Zepeelin.jpg',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
      ),
      Song(
        title: 'Imagine', 
        artist: 'John Lennon', 
        album: 'Imagine', 
        genre: 'Pop', 
        duration: '3:07', 
        isDefault: true, 
        imageUrl: 'defaults/john_lennon.jpg',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
      ),
    ];

    for (final song in defaults) {
      // 1. Check if this specific song already exists
      final snapshot = await _firestore.collection(_collection)
          .where('isDefault', isEqualTo: true)
          .where('title', isEqualTo: song.title)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // DEDUPLICATION: If more than 1 exists, keep first, delete others
        if (snapshot.docs.length > 1) {
          print('Cleanup: Found ${snapshot.docs.length} copies of ${song.title}. Deleting extras...');
          for (var i = 1; i < snapshot.docs.length; i++) {
            await snapshot.docs[i].reference.delete();
          }
        }
        print('Skipping ${song.title} (already exists)');
        continue; 
      }

      // 2. If not exists, upload and create
      try {
        final localPath = 'assets/images/${song.imageUrl}';
        final ByteData byteData = await rootBundle.load(localPath);
        final Uint8List imageData = byteData.buffer.asUint8List();
        
        final fileName = song.imageUrl.split('/').last;
        final ref = _storage.ref().child('defaults/$fileName');
        
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        await ref.putData(imageData, metadata);
        final downloadUrl = await ref.getDownloadURL();
        
        await addSong(song.copyWith(imageUrl: downloadUrl));
        print('CREATED: ${song.title}');
        
      } catch (e) {
        print('ERROR SEEDING ${song.title}: $e');
        // Fallback if local asset missing, use placeholder to not break app
        await addSong(song.copyWith(imageUrl: 'https://picsum.photos/seed/${song.title}/300/300'));
      }
    }
  }
}
