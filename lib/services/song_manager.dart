/* import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

import '../models/song.dart';

class SongManager {
  static const String _cacheKey = 'cached_songs';
  static List<Song>? _cachedSongs;

  /// Returns cached or freshly scanned list of songs.
  static Future<List<Song>> getSongs({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedSongs != null) return _cachedSongs!;

    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson != null) {
        try {
          final decoded = jsonDecode(cachedJson) as List;
          _cachedSongs = decoded.map((item) => Song.fromJson(item)).toList();
          return _cachedSongs!;
        } catch (e, stack) {
          log('Error parsing cached songs: $e', stackTrace: stack);
        }
      }
    }

    _cachedSongs = await _scanForSongs();
    await prefs.setString(_cacheKey, jsonEncode(_cachedSongs!.map((s) => s.toJson()).toList()));
    return _cachedSongs!;
  }

  /// Scans common directories for music files.
  static Future<List<Song>> _scanForSongs() async {
    final List<Song> songs = [];
    final List<Directory> scanDirs = [
      Directory('/storage/emulated/0/Music'),
      Directory('/storage/emulated/0/Download'),
      Directory('/storage/emulated/0'),
    ];

    for (final dir in scanDirs) {
      if (await dir.exists()) {
        await _scanDirectory(dir, songs);
      }
    }

    log('Found ${songs.length} songs');
    return songs;
  }

  /// Scans a directory recursively and adds valid songs to the list.
  static Future<void> _scanDirectory(Directory dir, List<Song> songs) async {
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;

        final lowerPath = entity.path.toLowerCase();
        if (lowerPath.endsWith('.mp3') || lowerPath.endsWith('.wav') || lowerPath.endsWith('.aac')) {
          try {
            final metadata = await MetadataRetriever.fromFile(entity);

            final song = Song(
              title: metadata.trackName ?? p.basenameWithoutExtension(entity.path),
              artist: metadata.trackArtistNames?.join(', '),
              album: metadata.albumName,
              albumArt: metadata.albumArt,
              duration: metadata.trackDuration ?? 0, // Provide default if null
              path: entity.path,
            );

            songs.add(song);
          } catch (e, stack) {
            log('Metadata error for ${entity.path}: $e', stackTrace: stack);
            songs.add(Song.fromPath(entity.path));
          }
        }
      }
    } catch (e, stack) {
      log('Error scanning directory "${dir.path}": $e', stackTrace: stack);
    }
  }
}
 */