import 'dart:convert';
import 'package:http/http.dart' as http;

class ItunesService {
  static const String _baseUrl = 'https://itunes.apple.com/search';

  static Future<List<Map<String, dynamic>>> searchSongs(String query) async {
    try {
      final url = Uri.parse('$_baseUrl?term=${Uri.encodeComponent(query)}&media=music&entity=song&limit=15');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        return results.map((item) => {
          'title': item['trackName'] ?? 'Desconocido',
          'artist': item['artistName'] ?? 'Desconocido',
          'album': item['collectionName'] ?? '',
          'genre': item['primaryGenreName'] ?? 'Pop',
          // Modificamos la URL para obtener la portada en alta resolución (500x500 en lugar de 100x100)
          'imageUrl': (item['artworkUrl100'] as String?)?.replaceAll('100x100bb', '500x500bb') ?? '',
          'audioUrl': item['previewUrl'] ?? '',
          'duration': '0:30', // Las previews de Apple Music son siempre de 30 segundos
        }).where((song) => song['audioUrl'].toString().isNotEmpty).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
