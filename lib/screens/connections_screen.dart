import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_theme.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/social_provider.dart';
import 'user_profile_screen.dart';

class ConnectionsScreen extends StatefulWidget {
  final String userId;
  final String title;
  final bool isFollowers; // true = followers, false = following

  const ConnectionsScreen({
    super.key,
    required this.userId,
    required this.title,
    required this.isFollowers,
  });

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  late Future<List<UserProfile>> _futureUsers;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    final provider = context.read<SocialProvider>();
    _futureUsers = widget.isFollowers 
        ? provider.getFollowers(widget.userId) 
        : provider.getFollowing(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<UserProfile>>(
        future: _futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(
              child: Text(
                widget.isFollowers ? 'Aún no tiene seguidores' : 'No sigue a nadie aún',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => Divider(color: AppColors.divider.withAlpha(50), height: 1, indent: 76),
            itemBuilder: (context, index) {
              final user = users[index];
              final isFollowing = context.watch<SocialProvider>().isFollowing(user.id);
              final isMe = user.id == currentUserId;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.surfaceLight,
                  backgroundImage: user.imageUrl.isNotEmpty ? CachedNetworkImageProvider(user.imageUrl) : null,
                  child: user.imageUrl.isEmpty 
                      ? Text(
                          user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                          style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 20),
                        )
                      : null,
                ),
                title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${user.followersCount} seguidores', style: const TextStyle(color: AppColors.textMuted)),
                trailing: isMe 
                    ? const SizedBox.shrink()
                    : OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isFollowing ? Colors.transparent : AppColors.primary,
                          side: BorderSide(color: isFollowing ? AppColors.primary : Colors.transparent),
                          foregroundColor: isFollowing ? AppColors.primary : Colors.black,
                        ),
                        onPressed: () {
                          context.read<SocialProvider>().toggleFollow(currentUserId, user.id);
                        },
                        child: Text(isFollowing ? 'Siguiendo' : 'Seguir'),
                      ),
                onTap: () {
                  if (isMe) {
                    Navigator.pop(context); // Go back if clicking myself
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)));
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
