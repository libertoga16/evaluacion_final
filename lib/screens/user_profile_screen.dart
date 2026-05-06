import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/user_profile.dart';
import '../../models/song.dart';
import '../../models/playlist.dart';
import '../../providers/auth_provider.dart';
import '../../providers/social_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/widgets.dart';
import 'song_detail_screen.dart';
import 'playlist_detail_screen.dart';
import 'connections_screen.dart';

class UserProfileScreen extends StatelessWidget {
  final UserProfile user;

  const UserProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().userId;
    final isFollowing = context.watch<SocialProvider>().isFollowing(user.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(user.displayName),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing ? Colors.transparent : AppColors.primary,
                side: BorderSide(color: isFollowing ? AppColors.primary : Colors.transparent),
                foregroundColor: isFollowing ? AppColors.primary : Colors.black,
              ),
              onPressed: () {
                context.read<SocialProvider>().toggleFollow(currentUserId, user.id);
              },
              child: Text(isFollowing ? 'Siguiendo' : 'Seguir'),
            ),
          )
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.surfaceLight,
                    backgroundImage: user.imageUrl.isNotEmpty ? CachedNetworkImageProvider(user.imageUrl) : null,
                    child: user.imageUrl.isEmpty 
                        ? Text(
                            user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                            style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 36),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(user.displayName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ConnectionsScreen(
                            userId: user.id, 
                            title: 'Seguidores de ${user.displayName}', 
                            isFollowers: true,
                          )));
                        },
                        child: _buildStatColumn('Seguidores', user.followersCount.toString()),
                      ),
                      const SizedBox(width: 32),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ConnectionsScreen(
                            userId: user.id, 
                            title: '${user.displayName} sigue a', 
                            isFollowers: false,
                          )));
                        },
                        child: _buildStatColumn('Siguiendo', user.followingCount.toString()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const TabBar(
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              tabs: [
                Tab(text: 'Playlists Públicas'),
                Tab(text: 'Canciones Subidas'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPlaylistsTab(context),
                  _buildSongsTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ],
    );
  }

  Widget _buildPlaylistsTab(BuildContext context) {
    return StreamBuilder<List<Playlist>>(
      stream: context.read<SocialProvider>().getUserPlaylists(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final playlists = snapshot.data ?? [];
        if (playlists.isEmpty) return const Center(child: Text('No hay playlists públicas', style: TextStyle(color: AppColors.textMuted)));

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final pl = playlists[index];
            return PlaylistCardWidget(
              playlist: pl,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: pl))),
            );
          },
        );
      },
    );
  }

  Widget _buildSongsTab(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().userId;
    return StreamBuilder<List<Song>>(
      stream: context.read<SocialProvider>().getUserSongs(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        var songs = snapshot.data ?? [];
        // Si visitas el perfil de otro, solo ver sus canciones públicas
        if (user.id != currentUserId) {
          songs = songs.where((s) => s.isPublic).toList();
        }
        if (songs.isEmpty) return const Center(child: Text('No ha subido canciones', style: TextStyle(color: AppColors.textMuted)));

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: songs.length,
          separatorBuilder: (_, __) => Divider(color: AppColors.divider.withAlpha(50), height: 1, indent: 76),
          itemBuilder: (context, index) {
            final song = songs[index];
            return SongTileWidget(
              title: song.title,
              subtitle: '${song.artist} • ${song.duration}',
              imageUrl: song.imageUrl,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SongDetailScreen(song: song))),
            );
          },
        );
      },
    );
  }
}
