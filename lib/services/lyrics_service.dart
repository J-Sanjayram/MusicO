import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';

class LyricsService {
  static Future<String?> fetchLyrics(Song song) async {
    
    final query =  buildLyricsQuery(song);
    final url = Uri.parse("https://lrclib.net/api/search?q=$query");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      print(data);

      if (data.isNotEmpty && data[0]["syncedLyrics"] != null) {
        return data[0]["syncedLyrics"];
      } else if (data.isNotEmpty && data[0]["plainLyrics"] != null) {
        return data[0]["plainLyrics"];
      } else {
        return "Lyrics not found.";
      }
    } else {
      return "Failed to load lyrics.";
    }
  }
  static String buildLyricsQuery(Song song) {
  // Keep only text before first hyphen
  String title = song.title.split('-').first.trim();
  //print("THE ARTIST"+ song.artist.toString());

  // Clean up artist too (remove masstamilan and related words)
  String artist = (song.artist ?? '').replaceAll(RegExp(r'\bmasstamilan(\.com|\.in)?\b', caseSensitive: false), '').trim();
  //print(Uri.encodeComponent(("$title $artist").trim()));

  return Uri.encodeComponent(("$title $artist").trim());
}

}
