// lib/utils/isolate_handlers.dart
import 'package:flutter/foundation.dart'; // For compute
import '../models/song.dart';
import '../services/audio_service.dart'; // Assuming your AudioService class is here

// This is the function that will run in the new Isolate.
// It must be a top-level function or a static method.
Future<List<Song>> _scanSongsInBackground(bool forceRefresh) async {
  // This code runs in a separate Isolate, not on the UI thread.
  debugPrint('Isolate: Starting song scan...');
  try {
    final songs = await AudioService.getSongs(forceRefresh: forceRefresh);
    debugPrint('Isolate: Song scan complete. Found ${songs.length} songs.');
    return songs;
  } catch (e) {
    debugPrint('Isolate: Error scanning songs: $e');
    rethrow; // Re-throw to propagate the error back to the main isolate
  }
}

// A helper function to easily call the isolate
Future<List<Song>> scanSongsInIsolate({required bool forceRefresh}) async {
  return await compute(_scanSongsInBackground, forceRefresh);
}

// If you need to send progress updates back from the isolate,
// you'd typically use a ReceivePort/SendPort pair.
// For simpler cases like this, where you just need the final result,
// `compute` is a good high-level abstraction.
// If your AudioService.getSongs actually emits progress via a stream,
// you would need a more complex Isolate setup with ReceivePort/SendPort.
// For now, let's assume `AudioService.getSongs` just returns a Future<List<Song>>.