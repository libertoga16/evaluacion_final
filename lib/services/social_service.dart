import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<UserProfile>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserProfile.fromMap(doc.id, doc.data())).toList();
    });
  }

  Stream<UserProfile> getUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) throw Exception('Usuario no encontrado');
      return UserProfile.fromMap(doc.id, doc.data()!);
    });
  }

  Stream<List<String>> getFollowingIds(String currentUserId) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Future<void> toggleFollow(String currentUserId, String targetUserId) async {
    final followingRef = _firestore.collection('users').doc(currentUserId).collection('following').doc(targetUserId);
    final followersRef = _firestore.collection('users').doc(targetUserId).collection('followers').doc(currentUserId);
    
    final targetUserRef = _firestore.collection('users').doc(targetUserId);
    final currentUserRef = _firestore.collection('users').doc(currentUserId);

    final isFollowing = (await followingRef.get()).exists;

    if (isFollowing) {
      await followingRef.delete();
      await followersRef.delete();
      await targetUserRef.set({'followersCount': FieldValue.increment(-1)}, SetOptions(merge: true));
      await currentUserRef.set({'followingCount': FieldValue.increment(-1)}, SetOptions(merge: true));
    } else {
      await followingRef.set({'timestamp': FieldValue.serverTimestamp()});
      await followersRef.set({'timestamp': FieldValue.serverTimestamp()});
      await targetUserRef.set({'followersCount': FieldValue.increment(1)}, SetOptions(merge: true));
      await currentUserRef.set({'followingCount': FieldValue.increment(1)}, SetOptions(merge: true));
    }
  }

  Stream<List<Song>> getUserSongs(String userId) {
    return _firestore
        .collection('songs')
        .where('createdBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Song.fromFirestore(doc)).toList());
  }

  Stream<List<Playlist>> getUserPlaylists(String userId) {
    return _firestore
        .collection('playlists')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Playlist.fromFirestore(doc)).toList());
  }

  Future<List<UserProfile>> getFollowers(String userId) async {
    final snapshot = await _firestore.collection('users').doc(userId).collection('followers').get();
    final List<UserProfile> users = [];
    for (var doc in snapshot.docs) {
      final userDoc = await _firestore.collection('users').doc(doc.id).get();
      if (userDoc.exists) {
        users.add(UserProfile.fromMap(userDoc.id, userDoc.data()!));
      }
    }
    return users;
  }

  Future<List<UserProfile>> getFollowing(String userId) async {
    final snapshot = await _firestore.collection('users').doc(userId).collection('following').get();
    final List<UserProfile> users = [];
    for (var doc in snapshot.docs) {
      final userDoc = await _firestore.collection('users').doc(doc.id).get();
      if (userDoc.exists) {
        users.add(UserProfile.fromMap(userDoc.id, userDoc.data()!));
      }
    }
    return users;
  }
}
