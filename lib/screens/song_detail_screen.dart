import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../widgets/widgets.dart';
import 'song_form_screen.dart';

class SongDetailScreen extends StatelessWidget {
  final Song song;
  const SongDetailScreen({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().userId;
    final canEdit = !song.isDefault && song.createdBy == userId;
    final music = context.watch<MusicProvider>();
    final isFav = music.isFavorite(song.id ?? '');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            actions: [
              FavoriteButton(
                isFavorite: isFav,
                onTap: () => music.toggleFavorite(userId, song.id ?? ''),
                size: 28,
              ),
              if (canEdit) ...[
                IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SongFormScreen(song: song)))),
                IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete(context, song.id!)),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: song.imageUrl.isNotEmpty
                  ? CachedNetworkImage(imageUrl: song.imageUrl, fit: BoxFit.cover, color: Colors.black45, colorBlendMode: BlendMode.darken)
                  : Container(color: AppColors.surfaceLight, child: const Icon(Icons.music_note, size: 100, color: AppColors.textMuted)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(song.artist, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 32),
                  
                  if (song.audioUrl.isNotEmpty) 
                    AudioPlayerWidget(audioUrl: song.audioUrl, autoPlay: true)
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.surfaceLight.withAlpha(50), borderRadius: BorderRadius.circular(12)),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.textMuted),
                          SizedBox(width: 12),
                          Text('Vista previa de audio no disponible', style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    
                  const SizedBox(height: 32),
                  _buildInfoSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      children: [
        _buildInfoRow(Icons.album, 'Álbum', song.album.isNotEmpty ? song.album : 'Sencillo'),
        _buildInfoRow(Icons.category, 'Género', song.genre.isNotEmpty ? song.genre : 'Desconocido'),
        _buildInfoRow(Icons.timer, 'Duración', song.duration),
        if (song.isDefault)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
               Icon(Icons.verified, color: AppColors.primary, size: 20),
               SizedBox(width: 12),
               Text('Verificado por MelodyVault', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ]),
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar canción'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<MusicProvider>().deleteSong(id);
      Navigator.pop(context);
    }
  }
}
