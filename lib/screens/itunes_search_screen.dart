import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../config/app_theme.dart';
import '../services/itunes_service.dart';
import '../providers/music_provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';

class ItunesSearchScreen extends StatefulWidget {
  const ItunesSearchScreen({super.key});

  @override
  State<ItunesSearchScreen> createState() => _ItunesSearchScreenState();
}

class _ItunesSearchScreenState extends State<ItunesSearchScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _isDownloading = false;

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    
    // Ocultar teclado
    FocusScope.of(context).unfocus();
    
    final results = await ItunesService.searchSongs(query);
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  Future<void> _downloadAndSave(Map<String, dynamic> songData) async {
    setState(() => _isDownloading = true);
    try {
      // 1. Descargamos en memoria temporal (Caché del dispositivo)
      final tempDir = await getTemporaryDirectory();
      
      // Descargar el audio
      final audioUrl = songData['audioUrl'];
      final audioRes = await http.get(Uri.parse(audioUrl));
      final audioFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a');
      await audioFile.writeAsBytes(audioRes.bodyBytes);

      // Descargar la portada
      final imageUrl = songData['imageUrl'];
      File? imageFile;
      if (imageUrl.isNotEmpty) {
        final imageRes = await http.get(Uri.parse(imageUrl));
        imageFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await imageFile.writeAsBytes(imageRes.bodyBytes);
      }

      final musicProvider = context.read<MusicProvider>();
      final authProvider = context.read<AuthProvider>();
      
      final song = Song(
        title: songData['title'],
        artist: songData['artist'],
        album: songData['album'],
        genre: songData['genre'],
        duration: songData['duration'],
        imageUrl: '',
        audioUrl: '',
        isDefault: false,
        isPublic: false, // Las canciones de iTunes se guardan como privadas por defecto
        createdBy: authProvider.userId,
      );

      final resultId = await musicProvider.addSong(
        song,
        imageFile,
        audioFile,
        authProvider.userId,
      );
      
      final success = resultId != null;

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎵 ¡Añadida con éxito a tu perfil!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Volver a la pantalla anterior
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(musicProvider.error ?? 'Error al subir a tu perfil'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de red: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nube Global (iTunes)'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar artista, álbum o canción...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _isLoading || _isDownloading ? null : _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          if (_isDownloading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Obteniendo archivos y subiendo a tu nube...', 
                    style: TextStyle(color: AppColors.textSecondary)
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty 
                    ? const Center(
                        child: Text('Busca tu música favorita', 
                          style: TextStyle(color: AppColors.textMuted)
                        )
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final song = _results[index];
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: song['imageUrl'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: AppColors.surfaceLight),
                                errorWidget: (context, url, error) => Container(color: AppColors.surfaceLight, child: const Icon(Icons.music_note)),
                              ),
                            ),
                            title: Text(song['title'], maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${song['artist']} • ${song['genre']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: _isDownloading 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                : IconButton(
                                    icon: const Icon(Icons.cloud_download, color: AppColors.primary),
                                    onPressed: () => _downloadAndSave(song),
                                  ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
