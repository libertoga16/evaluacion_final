import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../widgets/widgets.dart';
import 'song_detail_screen.dart';
import 'playlist_form_screen.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Song>>(
        future: context.read<MusicProvider>().getSongsByIds(playlist.songIds),
        builder: (context, snapshot) {
          final songs = snapshot.data ?? [];
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistFormScreen(playlist: playlist))),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(playlist.name, style: const TextStyle(shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                       if (playlist.imageUrl.isNotEmpty)
                          CachedNetworkImage(imageUrl: playlist.imageUrl, fit: BoxFit.cover, color: Colors.black45, colorBlendMode: BlendMode.darken),
                       if (playlist.imageUrl.isEmpty)
                          Container(color: AppColors.surfaceLight, child: const Icon(Icons.queue_music, size: 100, color: AppColors.textMuted)),
                       const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xFF121212)],
                              stops: [0.6, 1.0],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (playlist.description.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(playlist.description, style: const TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${songs.length} canciones', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      TextButton.icon(
                        onPressed: () => _showAddSongDialog(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Añadir canciones'),
                      ),
                    ],
                  ),
                ),
              ),
              if (isLoading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else if (songs.isEmpty)
                const SliverFillRemaining(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Esta playlist está vacía.\n¡Añade algunas canciones!', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted))),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = songs[index];
                      return Dismissible(
                        key: Key(song.id!),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: AppColors.error,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          context.read<MusicProvider>().removeSongFromPlaylist(playlist.id!, song.id!);
                        },
                        child: SongTileWidget(
                          title: song.title,
                          subtitle: song.artist,
                          imageUrl: song.imageUrl,
                          hasAudio: song.audioUrl.isNotEmpty,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SongDetailScreen(song: song))),
                          showActions: true,
                          onDelete: () => context.read<MusicProvider>().removeSongFromPlaylist(playlist.id!, song.id!),
                        ),
                      );
                    },
                    childCount: songs.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar playlist'),
        content: Text('¿Eliminar "${playlist.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<MusicProvider>().deletePlaylist(playlist.id!);
      Navigator.pop(context);
    }
  }

  void _showAddSongDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return _AddSongSheet(playlistId: playlist.id!, scrollController: controller);
          },
        );
      },
    );
  }
}

class _AddSongSheet extends StatefulWidget {
  final String playlistId;
  final ScrollController scrollController;
  const _AddSongSheet({required this.playlistId, required this.scrollController});

  @override
  State<_AddSongSheet> createState() => _AddSongSheetState();
}

class _AddSongSheetState extends State<_AddSongSheet> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Añadir a la playlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: StreamBuilder<List<Song>>(
            stream: context.read<MusicProvider>().songsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final songs = snapshot.data ?? [];
              
              if (songs.isEmpty) return const Center(child: Text('No hay canciones disponibles'));

              return ListView.builder(
                controller: widget.scrollController,
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: song.imageUrl.isNotEmpty
                          ? CachedNetworkImage(imageUrl: song.imageUrl, width: 40, height: 40, fit: BoxFit.cover)
                          : Container(width: 40, height: 40, color: AppColors.surfaceLight, child: const Icon(Icons.music_note)),
                    ),
                    title: Text(song.title),
                    subtitle: Text(song.artist),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.primary),
                      onPressed: () {
                         context.read<MusicProvider>().addSongToPlaylist(widget.playlistId, song.id!);
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${song.title}" añadida'), duration: const Duration(milliseconds: 800)));
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
