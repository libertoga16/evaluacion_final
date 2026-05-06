import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MockSeeder {
  static Future<void> seedDatabase() async {
    debugPrint('Iniciando carga de usuarios y datos falsos...');
    final firestore = FirebaseFirestore.instance;

    debugPrint('Borrando usuarios antiguos (excepto feriafp@gmail.com)...');
    final existingUsers = await firestore.collection('users').get();
    final keepIds = [
      'mock_user_1', 'mock_user_2', 'mock_user_3', 
      'mock_user_4', 'mock_user_5', 'mock_user_6'
    ];
    
    for (var doc in existingUsers.docs) {
      final email = doc.data()['email'] ?? '';
      if (!keepIds.contains(doc.id) && email != 'feriafp@gmail.com') {
        await doc.reference.delete();
      }
    }

    // 1. Crear usuarios falsos
    final users = [
      {
        'id': 'mock_user_1',
        'displayName': 'DJ_Alex',
        'email': 'alex@mock.com',
        'imageUrl': 'https://i.pravatar.cc/150?u=alex',
        'followersCount': 3,
        'followingCount': 2,
      },
      {
        'id': 'mock_user_2',
        'displayName': 'RockerGirl',
        'email': 'rocker@mock.com',
        'imageUrl': 'https://i.pravatar.cc/150?u=rocker',
        'followersCount': 2,
        'followingCount': 2,
      },
      {
        'id': 'mock_user_3',
        'displayName': 'SynthMaster',
        'email': 'synth@mock.com',
        'imageUrl': 'https://i.pravatar.cc/150?u=synth',
        'followersCount': 2,
        'followingCount': 1,
      },
      {
        'id': 'mock_user_4',
        'displayName': 'BeatMaster',
        'email': 'beat@mock.com',
        'imageUrl': 'https://i.pravatar.cc/150?u=beat',
        'followersCount': 1,
        'followingCount': 2,
      },
      {
        'id': 'mock_user_5',
        'displayName': 'LunaVox',
        'email': 'luna@mock.com',
        'imageUrl': 'https://i.pravatar.cc/150?u=luna',
        'followersCount': 2,
        'followingCount': 1,
      },
      {
        'id': 'mock_user_6',
        'displayName': 'BassKing',
        'email': 'bass@mock.com',
        'imageUrl': 'https://i.pravatar.cc/150?u=bass',
        'followersCount': 1,
        'followingCount': 3,
      },
    ];

    for (var u in users) {
      await firestore.collection('users').doc(u['id'] as String).set({
        'displayName': u['displayName'],
        'email': u['email'],
        'imageUrl': u['imageUrl'],
        'followersCount': u['followersCount'],
        'followingCount': u['followingCount'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // 2. Crear relaciones de seguidores
    // Alex
    await _follow(firestore, 'mock_user_1', 'mock_user_2');
    await _follow(firestore, 'mock_user_1', 'mock_user_4');
    // RockerGirl
    await _follow(firestore, 'mock_user_2', 'mock_user_1');
    await _follow(firestore, 'mock_user_2', 'mock_user_5');
    // SynthMaster
    await _follow(firestore, 'mock_user_3', 'mock_user_1');
    // Nuevos
    await _follow(firestore, 'mock_user_4', 'mock_user_2');
    await _follow(firestore, 'mock_user_4', 'mock_user_6');
    await _follow(firestore, 'mock_user_5', 'mock_user_3');
    await _follow(firestore, 'mock_user_6', 'mock_user_1');
    await _follow(firestore, 'mock_user_6', 'mock_user_3');
    await _follow(firestore, 'mock_user_6', 'mock_user_5');

    // 3. Crear canciones subidas por estos usuarios falsos
    final songs = [
      {
        'title': 'Neon Nights',
        'artist': 'SynthMaster',
        'album': 'Cyber Drive',
        'genre': 'Electrónica',
        'duration': '3:45',
        'imageUrl': 'https://images.unsplash.com/photo-1614624532983-4ce03382d63d?w=500',
        'audioUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3',
        'isDefault': false,
        'createdBy': 'mock_user_3',
      },
      {
        'title': 'Acoustic Sunrise',
        'artist': 'RockerGirl',
        'album': 'Unplugged',
        'genre': 'Rock',
        'duration': '4:12',
        'imageUrl': 'https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?w=500',
        'audioUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3',
        'isDefault': false,
        'createdBy': 'mock_user_2',
      },
      {
        'title': 'Club Banger',
        'artist': 'DJ_Alex',
        'album': 'Summer Mix',
        'genre': 'Pop',
        'duration': '2:50',
        'imageUrl': 'https://images.unsplash.com/photo-1574169208507-84376144848b?w=500',
        'audioUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3',
        'isDefault': false,
        'createdBy': 'mock_user_1',
      },
      {
        'title': 'Lo-Fi Chill',
        'artist': 'BeatMaster',
        'album': 'Midnight Beats',
        'genre': 'Electrónica',
        'duration': '2:30',
        'imageUrl': 'https://images.unsplash.com/photo-1511367461989-f85a21fda167?w=500',
        'audioUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-13.mp3',
        'isDefault': false,
        'createdBy': 'mock_user_4',
      },
      {
        'title': 'Vocal Dreams',
        'artist': 'LunaVox',
        'album': 'Ethereal',
        'genre': 'Pop',
        'duration': '3:15',
        'imageUrl': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500',
        'audioUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-14.mp3',
        'isDefault': false,
        'createdBy': 'mock_user_5',
      },
      {
        'title': 'Heavy Drop',
        'artist': 'BassKing',
        'album': 'Subwoofer',
        'genre': 'Electrónica',
        'duration': '4:05',
        'imageUrl': 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=500',
        'audioUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-15.mp3',
        'isDefault': false,
        'createdBy': 'mock_user_6',
      },
    ];

    for (var s in songs) {
      await firestore.collection('songs').add({
        ...s,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    debugPrint('✅ Base de datos rellenada con éxito!');
  }

  static Future<void> _follow(FirebaseFirestore firestore, String follower, String target) async {
    await firestore.collection('users').doc(follower).collection('following').doc(target).set({'timestamp': FieldValue.serverTimestamp()});
    await firestore.collection('users').doc(target).collection('followers').doc(follower).set({'timestamp': FieldValue.serverTimestamp()});
  }
}
