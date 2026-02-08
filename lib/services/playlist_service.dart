import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/playlist.dart';

class PlaylistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _collection = 'playlists';

  Stream<List<Playlist>> getUserPlaylists(String userId) {
    return _firestore.collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Playlist.fromFirestore(d)).toList());
  }

  Future<Playlist?> getPlaylist(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    return doc.exists ? Playlist.fromFirestore(doc) : null;
  }

  Future<String> createPlaylist(Playlist playlist) async {
    final docRef = await _firestore.collection(_collection).add(playlist.toFirestore());
    return docRef.id;
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    if (playlist.id == null) throw Exception('Playlist ID required');
    await _firestore.collection(_collection).doc(playlist.id).update(playlist.toFirestore());
  }

  Future<void> deletePlaylist(String id) async {
    final playlist = await getPlaylist(id);
    if (playlist != null && playlist.imageUrl.isNotEmpty && playlist.imageUrl.contains('firebase')) {
      try { await _storage.refFromURL(playlist.imageUrl).delete(); } catch (_) {}
    }
    await _firestore.collection(_collection).doc(id).delete();
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    await _firestore.collection(_collection).doc(playlistId).update({
      'songIds': FieldValue.arrayUnion([songId]),
    });
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await _firestore.collection(_collection).doc(playlistId).update({
      'songIds': FieldValue.arrayRemove([songId]),
    });
  }

  Future<String> uploadImage(File file) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('playlist_images/$name');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}
