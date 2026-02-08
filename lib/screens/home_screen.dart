import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../widgets/widgets.dart';
import 'song_form_screen.dart';
import 'song_detail_screen.dart';
import 'playlists_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<AuthProvider>().userId;
      final music = context.read<MusicProvider>();
      music.seedDefaultSongs();
      music.initFavorites(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [SongsTab(), PlaylistsScreen(), ProfileTab()],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.library_music_rounded), label: 'Biblioteca'),
            BottomNavigationBarItem(icon: Icon(Icons.queue_music_rounded), label: 'Playlists'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}

class SongsTab extends StatefulWidget {
  const SongsTab({super.key});
  @override
  State<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends State<SongsTab> {
  String _searchQuery = '';
  bool _showFavoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca'),
        actions: [
          IconButton(
            icon: Icon(_showFavoritesOnly ? Icons.favorite : Icons.favorite_border, color: _showFavoritesOnly ? AppColors.primary : null),
            onPressed: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
            tooltip: 'Mostrar favoritos',
          ),
          AnimatedSearchBar(
            onChanged: (query) => setState(() => _searchQuery = query.toLowerCase()),
            hint: 'Buscar canción...',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SongFormScreen())),
          ),
        ],
      ),
      body: StreamBuilder<List<Song>>(
        stream: context.read<MusicProvider>().songsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 6,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                   ShimmerLoading(width: 52, height: 52, borderRadius: 6),
                   SizedBox(width: 12),
                   Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                     ShimmerLoading(height: 16, borderRadius: 4),
                     SizedBox(height: 8),
                     ShimmerLoading(height: 12, width: 100, borderRadius: 4),
                   ])),
                ]),
              ),
            );
          }
          
          var songs = snapshot.data ?? [];
          final music = context.watch<MusicProvider>();

          if (_showFavoritesOnly) {
            songs = songs.where((s) => music.isFavorite(s.id ?? '')).toList();
          }

          if (_searchQuery.isNotEmpty) {
            songs = songs.where((s) => s.title.toLowerCase().contains(_searchQuery) || s.artist.toLowerCase().contains(_searchQuery)).toList();
          }

          if (songs.isEmpty) {
            return EmptyStateWidget(
              icon: _showFavoritesOnly ? Icons.favorite_border : Icons.music_off_rounded,
              title: _showFavoritesOnly 
                  ? 'Sin favoritos' 
                  : (_searchQuery.isEmpty ? 'No hay canciones' : 'Sin resultados'),
              subtitle: _showFavoritesOnly 
                  ? 'Marca canciones con ❤️ para verlas aquí'
                  : (_searchQuery.isEmpty ? 'Añade tu primera canción' : 'Prueba con otra búsqueda'),
              action: !_showFavoritesOnly && _searchQuery.isEmpty ? GradientButton(
                text: 'Añadir Canción',
                icon: Icons.add,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SongFormScreen())),
              ) : null,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 80, top: 8),
            itemCount: songs.length,
            separatorBuilder: (_, __) => Divider(color: AppColors.divider.withAlpha(50), height: 1, indent: 76),
            itemBuilder: (context, index) {
              final song = songs[index];
              final canEdit = !song.isDefault && song.createdBy == userId;
              
              return SongTileWidget(
                title: song.title,
                subtitle: '${song.artist} • ${song.duration}',
                imageUrl: song.imageUrl,
                hasAudio: song.audioUrl.isNotEmpty,
                isDefault: song.isDefault,
                showActions: canEdit,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SongDetailScreen(song: song))),
                onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SongFormScreen(song: song))),
                onDelete: () => _confirmDelete(context, song),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Song song) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar canción'),
        content: Text('¿Eliminar "${song.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<MusicProvider>().deleteSong(song.id!);
    }
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 32),
          Center(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(60), blurRadius: 24, spreadRadius: 4)],
              ),
              child: CircleAvatar(
                radius: 56,
                backgroundColor: AppColors.primary,
                child: Text(
                  auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 48, color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(auth.displayName, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(auth.email, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 48),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              _buildStatRow(context, Icons.favorite, 'Canciones favoritas', 
                '${context.watch<MusicProvider>().favoriteIds.length}'), 
            ]),
          ),
          
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => auth.signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: AppColors.primary, size: 22),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    ]);
  }
}
