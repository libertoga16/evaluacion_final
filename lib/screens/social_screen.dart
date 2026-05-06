import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_theme.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/social_provider.dart';
import 'user_profile_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<AuthProvider>().userId;
      context.read<SocialProvider>().initFollowing(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().userId;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: AppColors.background.withAlpha(180)),
          ),
        ),
        title: const Text('Descubrir'),
      ),
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar usuarios...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserProfile>>(
              stream: context.read<SocialProvider>().allUsersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var users = snapshot.data ?? [];
                
                // Excluir al usuario actual
                users = users.where((u) => u.id != currentUserId).toList();
                
                // Filtrar por búsqueda
                if (_searchQuery.isNotEmpty) {
                  users = users.where((u) => u.displayName.toLowerCase().contains(_searchQuery)).toList();
                }

                if (users.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron usuarios', style: TextStyle(color: AppColors.textMuted)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 100), // Espacio para el mini player
                  itemCount: users.length,
                  separatorBuilder: (_, __) => Divider(color: AppColors.divider.withAlpha(50), height: 1, indent: 76),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isFollowing = context.watch<SocialProvider>().isFollowing(user.id);

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
                      trailing: OutlinedButton(
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
                        Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
