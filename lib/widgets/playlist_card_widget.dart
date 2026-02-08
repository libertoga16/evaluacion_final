import 'package:flutter/material.dart';
import '../models/models.dart';
import '../config/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PlaylistCardWidget extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const PlaylistCardWidget({super.key, required this.playlist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: playlist.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: playlist.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => Container(color: AppColors.surface, child: const Icon(Icons.music_note, color: AppColors.textMuted)),
                      errorWidget: (_, __, ___) => Container(color: AppColors.surface, child: const Icon(Icons.error)),
                    )
                  : Container(
                      color: AppColors.surface,
                      alignment: Alignment.center,
                      child: const Icon(Icons.queue_music, size: 40, color: AppColors.textMuted),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${playlist.songCount} canciones',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
