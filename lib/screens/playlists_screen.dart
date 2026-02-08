import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../widgets/widgets.dart';
import 'playlist_detail_screen.dart';
import 'playlist_form_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaylistFormScreen())),
          ),
        ],
      ),
      body: StreamBuilder<List<Playlist>>(
        stream: context.read<MusicProvider>().getUserPlaylists(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: 4,
              itemBuilder: (_, __) => const ShimmerLoading(height: 200, borderRadius: 8),
            );
          }

          final playlists = snapshot.data ?? [];

          if (playlists.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.queue_music,
              title: 'Crea tu primera playlist',
              subtitle: 'Organiza tu música favorita',
              action: GradientButton(
                text: 'Nueva Playlist',
                icon: Icons.add,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaylistFormScreen())),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return PlaylistCardWidget(
                playlist: playlist,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: playlist))),
              );
            },
          );
        },
      ),
    );
  }
}
