import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import 'dart:async';
import 'package:flutter/material.dart'; // For debugPrint

class AudioService {
  static const MethodChannel _platform = MethodChannel('com.example.musico/media_store');
  // The progress stream is not actively used in your current UI
  // but if you have a progress indicator for scanning, it would use this.
  static final StreamController<double> _progressController = StreamController.broadcast();

  static Stream<double> get progressStream => _progressController.stream;

  static Future<List<Song>> getSongs({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cachedJson = prefs.getString('cached_songs');
      if (cachedJson != null) {
        debugPrint('AudioService: Loading songs from cache.');
        final List decoded = jsonDecode(cachedJson);
        return decoded.map((s) => Song.fromJson(s)).toList();
      }
    }

    debugPrint('AudioService: Scanning for new songs...');
    try {
      final List result = await _platform.invokeMethod('getSongs');
      final List<Song> songs = result.map((s) {
            final map = Map<String, dynamic>.from(s);
            // Convert platform-specific data if needed
            if (map['albumArt'] is List) {
                map['albumArt'] = Uint8List.fromList((map['albumArt'] as List).cast<int>());
            }
            return Song.fromPlatformMap(map);
        }).toList();
      final encoded = jsonEncode(songs.map((s) => s.toJson()).toList());
      await prefs.setString('cached_songs', encoded);
      await prefs.setBool('has_scanned_once', true);

      _progressController.add(1.0); // Indicate 100% completion
      debugPrint('AudioService: Found ${songs.length} songs.');
      return songs;
    } catch (e) {
      debugPrint('AudioService: Error getting songs: $e');
      _progressController.add(1.0); // Still indicate completion even on error
      return [];
    }
  }

  static void dispose() {
    _progressController.close();
  }
}