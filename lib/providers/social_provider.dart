import 'package:flutter/material.dart';
import '../services/social_service.dart';
import '../models/user_profile.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class SocialProvider extends ChangeNotifier {
  final SocialService _socialService = SocialService();
  
  List<String> _followingIds = [];
  bool _isLoading = false;
  String? _error;

  List<String> get followingIds => _followingIds;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<UserProfile>> get allUsersStream => _socialService.getAllUsers();

  void initFollowing(String userId) {
    if (userId.isEmpty) return;
    _socialService.getFollowingIds(userId).listen((ids) {
      _followingIds = ids;
      notifyListeners();
    });
  }

  bool isFollowing(String targetUserId) => _followingIds.contains(targetUserId);

  Future<void> toggleFollow(String currentUserId, String targetUserId) async {
    if (currentUserId.isEmpty || targetUserId.isEmpty) return;
    try {
      await _socialService.toggleFollow(currentUserId, targetUserId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Stream<UserProfile> getUserProfile(String userId) => _socialService.getUserProfile(userId);
  Stream<List<Song>> getUserSongs(String userId) => _socialService.getUserSongs(userId);
  Stream<List<Playlist>> getUserPlaylists(String userId) => _socialService.getUserPlaylists(userId);

  Future<List<UserProfile>> getFollowers(String userId) => _socialService.getFollowers(userId);
  Future<List<UserProfile>> getFollowing(String userId) => _socialService.getFollowing(userId);
}
