import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../widgets/widgets.dart';
import 'playlist_detail_screen.dart'; // Importante para la navegación

class PlaylistFormScreen extends StatefulWidget {
  final Playlist? playlist;
  const PlaylistFormScreen({super.key, this.playlist});
  @override
  State<PlaylistFormScreen> createState() => _PlaylistFormScreenState();
}

class _PlaylistFormScreenState extends State<PlaylistFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  File? _imageFile;
  bool _isLoading = false;

  bool get isEditing => widget.playlist != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlist?.name ?? '');
    _descController = TextEditingController(text: widget.playlist?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 500, maxHeight: 500, imageQuality: 80);
    if (image != null) setState(() => _imageFile = File(image.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final music = context.read<MusicProvider>();
    final userId = context.read<AuthProvider>().userId;

    final playlist = Playlist(
      id: widget.playlist?.id,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      imageUrl: widget.playlist?.imageUrl ?? '',
      userId: widget.playlist?.userId ?? userId,
      songIds: widget.playlist?.songIds ?? [],
    );

    String? newId;
    bool success;
    
    if (isEditing) {
      newId = widget.playlist!.id;
      success = await music.updatePlaylist(playlist, _imageFile);
    } else {
      newId = await music.createPlaylist(playlist, _imageFile);
      success = newId != null;
    }

    setState(() => _isLoading = false);
    
    if (mounted) {
      if (success && newId != null) {
        if (isEditing) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playlist actualizada'), backgroundColor: AppColors.success));
        } else {
           // Al crear, navegamos directamente al detalle para que el usuario pueda añadir canciones
           final newPlaylist = playlist.copyWith(id: newId, imageUrl: _imageFile != null ? '' : playlist.imageUrl);
           Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: newPlaylist)));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(music.error ?? 'Error al guardar'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Playlist' : 'Nueva Playlist')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: _imageFile != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))
                      : widget.playlist?.imageUrl.isNotEmpty == true
                          ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(widget.playlist!.imageUrl, fit: BoxFit.cover))
                          : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.add_photo_alternate, size: 48, color: AppColors.textMuted),
                              SizedBox(height: 12),
                              Text('Añadir portada', style: TextStyle(color: AppColors.textMuted)),
                            ]),
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre de la playlist', prefixIcon: Icon(Icons.queue_music)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Obligatorio' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Descripción (opcional)', prefixIcon: Icon(Icons.description)),
              maxLines: 3,
            ),
            const SizedBox(height: 48),
            Center(
              child: GradientButton(
                text: isEditing ? 'GUARDAR CAMBIOS' : 'CREAR PLAYLIST',
                onPressed: _submit,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
