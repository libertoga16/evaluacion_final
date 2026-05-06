import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/audio_player_provider.dart';
import '../config/app_theme.dart';
import '../screens/song_detail_screen.dart';

class GlobalMiniPlayer extends StatefulWidget {
  const GlobalMiniPlayer({super.key});

  @override
  State<GlobalMiniPlayer> createState() => _GlobalMiniPlayerState();
}

class _GlobalMiniPlayerState extends State<GlobalMiniPlayer> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioPlayerProvider>();
    final song = audioProvider.currentSong;

    if (song == null) return const SizedBox.shrink();

    if (audioProvider.isPlaying) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => SongDetailScreen(song: song)));
      },
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 72,
            margin: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withAlpha(150),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withAlpha(25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ]
            ),
            child: Row(
              children: [
                // Vinilo giratorio
                Hero(
                  tag: 'mini_player_album_${song.id}',
                  child: AnimatedBuilder(
                    animation: _rotationController,
                    builder: (_, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * 2 * 3.14159,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(80),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ]
                      ),
                      child: ClipOval(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (song.imageUrl.isNotEmpty)
                              CachedNetworkImage(
                                imageUrl: song.imageUrl,
                                fit: BoxFit.cover,
                                width: 52,
                                height: 52,
                                errorWidget: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white54),
                              ),
                            // Agujero del vinilo
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song.artist,
                        style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Botones
                IconButton(
                  icon: Icon(
                    audioProvider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    size: 38,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    if (audioProvider.isPlaying) {
                      audioProvider.pause();
                    } else {
                      audioProvider.resume();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 24),
                  onPressed: () => audioProvider.stop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
