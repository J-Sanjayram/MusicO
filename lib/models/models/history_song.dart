import 'package:hive/hive.dart';
import 'package:musico/models/song.dart';

part 'history_song.g.dart'; // This line is crucial for code generation

@HiveType(typeId: 1) // Assign a UNIQUE type ID (different from your main Song model if it's Hive-enabled)
class HistorySong {
  @HiveField(0)
  final String title;
  @HiveField(1)
  final String? artist;
  @HiveField(2)
  final String? path; // Still useful to store for re-playing the exact song
  @HiveField(3)
  final String? uri; // Still useful to store for re-playing the exact song

  HistorySong({
    required this.title,
    this.artist,
    this.path,
    this.uri,
  });

  // Optional: A convenience factory to convert from your full Song object
  factory HistorySong.fromSong(Song song) {
    return HistorySong(
      title: song.title,
      artist: song.artist,
      path: song.path,
      uri: song.uri,
    );
  }
}