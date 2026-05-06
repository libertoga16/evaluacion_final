import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../widgets/widgets.dart';
import 'itunes_search_screen.dart';

class SongFormScreen extends StatefulWidget {
  final Song? song;
  const SongFormScreen({super.key, this.song});
  @override
  State<SongFormScreen> createState() => _SongFormScreenState();
}

class _SongFormScreenState extends State<SongFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;
  late TextEditingController _durationController;
  String? _selectedGenre;
  File? _imageFile;
  File? _audioFile;
  String? _audioFileName;
  bool _isLoading = false;
  bool _isPublic = true;

  bool get isEditing => widget.song != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song?.title ?? '');
    _artistController = TextEditingController(text: widget.song?.artist ?? '');
    _albumController = TextEditingController(text: widget.song?.album ?? '');
    _durationController = TextEditingController(text: widget.song?.duration ?? '');
    _selectedGenre = widget.song?.genre;
    _isPublic = widget.song?.isPublic ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 500, maxHeight: 500, imageQuality: 80);
    if (image != null) setState(() => _imageFile = File(image.path));
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: false);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _audioFile = File(result.files.single.path!);
        _audioFileName = result.files.single.name;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final music = context.read<MusicProvider>();
    final userId = context.read<AuthProvider>().userId;

    final song = Song(
      id: widget.song?.id,
      title: _titleController.text.trim(),
      artist: _artistController.text.trim(),
      album: _albumController.text.trim(),
      genre: _selectedGenre ?? '',
      duration: _durationController.text.trim(),
      imageUrl: widget.song?.imageUrl ?? '',
      audioUrl: widget.song?.audioUrl ?? '',
      isDefault: false,
      isPublic: _isPublic,
      createdBy: widget.song?.createdBy ?? userId,
    );

    bool success;
    if (isEditing) {
      success = await music.updateSong(song, _imageFile, _audioFile);
    } else {
      success = await music.addSong(song, _imageFile, _audioFile, userId) != null;
    }

    setState(() => _isLoading = false);
    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Canción actualizada' : 'Canción añadida'), backgroundColor: AppColors.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(music.error ?? 'Error'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Canción' : 'Nueva Canción')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (!isEditing) ...[
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ItunesSearchScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.purple.shade700, Colors.blue.shade700]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.purple.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_download, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Buscar en Nube Global (iTunes)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.surfaceLight)),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('O SUBIR MANUALMENTE', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold))),
                    Expanded(child: Divider(color: AppColors.surfaceLight)),
                  ],
                ),
              ),
            ],
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
                child: _imageFile != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity))
                    : widget.song?.imageUrl.isNotEmpty == true
                        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(widget.song!.imageUrl, fit: BoxFit.cover, width: double.infinity))
                        : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_photo_alternate, size: 48, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Text('Añadir imagen', style: TextStyle(color: AppColors.textMuted)),
                          ]),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _pickAudio,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _audioFile != null ? AppColors.primary : Colors.transparent),
                ),
                child: Row(
                  children: [
                    Icon(_audioFile != null || widget.song?.audioUrl.isNotEmpty == true ? Icons.audiotrack : Icons.add, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _audioFileName ?? (widget.song?.audioUrl.isNotEmpty == true ? 'Audio cargado (Toque para cambiar)' : 'Añadir archivo MP3'),
                        style: TextStyle(color: _audioFile != null ? AppColors.textPrimary : AppColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_audioFile != null) IconButton(icon: const Icon(Icons.close, color: AppColors.error), onPressed: () => setState(() { _audioFile = null; _audioFileName = null; })),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título', prefixIcon: Icon(Icons.music_note)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Obligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _artistController,
              decoration: const InputDecoration(labelText: 'Artista', prefixIcon: Icon(Icons.person)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Obligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _albumController,
              decoration: const InputDecoration(labelText: 'Álbum (opcional)', prefixIcon: Icon(Icons.album)),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedGenre,
                  decoration: const InputDecoration(labelText: 'Género'),
                  items: Song.genres.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => _selectedGenre = v),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(labelText: 'Duración', hintText: '3:45'),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text('Canción pública'),
                subtitle: Text(_isPublic ? 'Visible para todos los usuarios' : 'Solo visible para ti', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                value: _isPublic,
                activeColor: AppColors.primary,
                secondary: Icon(_isPublic ? Icons.public : Icons.lock, color: AppColors.primary),
                onChanged: (v) => setState(() => _isPublic = v),
              ),
            ),
            const SizedBox(height: 48),
            Center(
              child: GradientButton(
                text: isEditing ? 'GUARDAR CAMBIOS' : 'AÑADIR CANCIÓN',
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
