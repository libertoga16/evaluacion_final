import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../services/song_service.dart';
import '../services/playlist_service.dart';

class MusicProvider extends ChangeNotifier {
  final SongService _songService = SongService();
  final PlaylistService _playlistService = PlaylistService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  String? _error;
  List<String> _favoriteIds = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get favoriteIds => _favoriteIds;

  Stream<List<Song>> get songsStream => _songService.getSongs();
  Stream<List<Playlist>> getUserPlaylists(String userId) => _playlistService.getUserPlaylists(userId);

  void initFavorites(String userId) {
    if (userId.isEmpty) return;
    _firestore.collection('users').doc(userId).collection('favorites').snapshots().listen((snapshot) {
      _favoriteIds = snapshot.docs.map((doc) => doc.id).toList();
      notifyListeners();
    });
  }

  Future<void> toggleFavorite(String userId, String songId) async {
    if (userId.isEmpty) return;
    final ref = _firestore.collection('users').doc(userId).collection('favorites').doc(songId);
    if (_favoriteIds.contains(songId)) {
      await ref.delete();
    } else {
      await ref.set({'addedAt': FieldValue.serverTimestamp()});
    }
  }

  bool isFavorite(String songId) => _favoriteIds.contains(songId);

  Future<void> seedDefaultSongs() async {
    await _songService.seedDefaultSongs();
  }

  Future<List<Song>> getSongsByIds(List<String> ids) async {
    return await _songService.getSongsByIds(ids);
  }

  Future<String?> addSong(Song song, File? imageFile, File? audioFile, String userId) async {
    _setLoading(true);
    try {
      String imageUrl = '';
      String audioUrl = '';
      if (imageFile != null) imageUrl = await _songService.uploadImage(imageFile);
      if (audioFile != null) audioUrl = await _songService.uploadAudio(audioFile);
      
      final newSong = song.copyWith(imageUrl: imageUrl, audioUrl: audioUrl, createdBy: userId, isDefault: false);
      final id = await _songService.addSong(newSong);
      _setLoading(false);
      return id;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
    }
  }

  Future<bool> updateSong(Song song, File? imageFile, File? audioFile) async {
    _setLoading(true);
    try {
      String imageUrl = song.imageUrl;
      String audioUrl = song.audioUrl;
      if (imageFile != null) imageUrl = await _songService.uploadImage(imageFile);
      if (audioFile != null) audioUrl = await _songService.uploadAudio(audioFile);
      
      await _songService.updateSong(song.copyWith(imageUrl: imageUrl, audioUrl: audioUrl));
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteSong(String id) async {
    _setLoading(true);
    try {
      final result = await _songService.deleteSong(id);
      _setLoading(false);
      if (!result) _error = 'No se puede eliminar una canción predeterminada';
      return result;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<String?> createPlaylist(Playlist playlist, File? imageFile) async {
    _setLoading(true);
    try {
      String imageUrl = '';
      if (imageFile != null && await imageFile.exists()) {
        try {
          imageUrl = await _playlistService.uploadImage(imageFile);
        } catch (e) {
          debugPrint('Error subiendo imagen playlist: $e');
        }
      }
      
      final newPlaylist = Playlist(
        name: playlist.name,
        description: playlist.description,
        imageUrl: imageUrl,
        userId: playlist.userId,
        songIds: playlist.songIds,
      );
      
      final id = await _playlistService.createPlaylist(newPlaylist);
      _setLoading(false);
      return id;
    } catch (e) {
      _error = 'Error creando playlist: $e';
      _setLoading(false);
      return null;
    }
  }

  Future<bool> updatePlaylist(Playlist playlist, File? imageFile) async {
    _setLoading(true);
    try {
      String imageUrl = playlist.imageUrl;
      if (imageFile != null && await imageFile.exists()) {
        try {
          imageUrl = await _playlistService.uploadImage(imageFile);
        } catch (e) {
           debugPrint('Error actualizando imagen playlist: $e');
        }
      }
      
      final updated = Playlist(
        id: playlist.id,
        name: playlist.name,
        description: playlist.description,
        imageUrl: imageUrl,
        userId: playlist.userId,
        songIds: playlist.songIds,
      );
      
      await _playlistService.updatePlaylist(updated);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Error actualizando playlist: $e';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deletePlaylist(String id) async {
    _setLoading(true);
    try {
      await _playlistService.deletePlaylist(id);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    await _playlistService.addSongToPlaylist(playlistId, songId);
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await _playlistService.removeSongFromPlaylist(playlistId, songId);
  }

  void clearError() { _error = null; notifyListeners(); }
  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
}
