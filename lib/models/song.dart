import 'dart:convert';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

class Song {
  final String? path;
  final String? uri; // New field for streaming URIs
  final String title;
  final String? artist;
  final String? album;
  final Uint8List? albumArt;
  final int duration;

  const Song({
    this.path,
    this.uri,
    required this.title,
    this.artist,
    this.album,
    this.albumArt,
    required this.duration,
  // ignore: unnecessary_null_comparison
  }):assert(path != null || uri != null, 'Either path or uri must be provided'); // Ensures one is present


  factory Song.fromPath(String path) {
    return Song(
      path: path,
      title: p.basenameWithoutExtension(path),
      artist: 'Unknown Artist',
      album: 'Unknown Album',
      albumArt: null,
      duration: 0,
    );
  }

  factory Song.fromUri({
    required String uri,
    required String title,
    String? artist,
    String? album,
    Uint8List? albumArt,
    required int duration,
  }) {
    return Song(
      uri: uri,
      title: title,
      artist: artist,
      album: album,
      albumArt: albumArt,
      duration: duration,
    );
  }
  
  Map<String, dynamic> toJson() => {
        'path': path,
        'uri': uri, // Include uri in JSON serialization

        'title': title,
        'artist': artist,
        'album': album,
        'duration': duration,
        // Base64 encode for JSON serialization (e.g., for SharedPreferences)
        'albumArt': albumArt != null ? base64Encode(albumArt!) : null,
      };

  factory Song.fromJson(Map<String, dynamic> json) => Song(
        path: json['path'],
        uri: json['uri'], // Include uri in JSON deserialization
        title: json['title'],
        artist: json['artist'],
        album: json['album'],
        duration: json['duration'] ?? 0,
        // Base64 decode when loading from JSON (e.g., from SharedPreferences)
        albumArt: json['albumArt'] != null
            ? base64Decode(json['albumArt'])
            : null,
      );

  // Corrected factory to handle Uint8List directly from platform channel
  factory Song.fromPlatformMap(Map<String, dynamic> map) {
    return Song(
      path: map['path'] as String,
      uri: map['uri'] as String?, // Add uri here for platform maps

      title: map['title'] as String? ?? 'Unknown Title',
      artist: map['artist'] as String?,
      album: map['album'] as String?,
      duration: map['duration'] as int? ?? 0,
      // If albumArt is already Uint8List (from AudioService's pre-processing),
      // just assign it directly. Do NOT base64Decode it here.
      albumArt: map['albumArt'] is Uint8List ? map['albumArt'] as Uint8List : null,
    );
  }
}

// lib/models/lyrics_line.dart
class LyricsLine {
  final Duration timestamp;
  final String text;

  LyricsLine(this.timestamp, this.text);

  @override
  String toString() => '[${timestamp.inMilliseconds}] $text';
}