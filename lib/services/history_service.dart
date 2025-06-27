import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
// For getApplicationDocumentsDirectory
import 'package:flutter/foundation.dart'; // For debugPrint

import '../models/models/history_song.dart'; // Import your new HistorySong model
import '../models/song.dart'; // You still need your main Song model for conversion

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;

  HistoryService._internal();

  static const String _historyBoxName = 'songHistoryMinimal'; // A distinct name for this box
  late Box<HistorySong> _historyBox; // Hive box will store HistorySong objects

  // Use a ValueNotifier to easily expose the history list to your UI
  final ValueNotifier<List<HistorySong>> songHistory = ValueNotifier([]);

  Future<void> init() async {
    // Hive is now initialized and adapters are registered in main.dart
    // So, we can directly open the box here.
    _historyBox = await Hive.openBox<HistorySong>(_historyBoxName);
    _loadHistory(); // Load history when the service initializes
    debugPrint('HistoryService initialized. History count: ${_historyBox.length}');
  }

  void _loadHistory() {
    // Get all songs from the box and reverse to show most recent first
    songHistory.value = _historyBox.values.toList().reversed.toList();
    debugPrint('History loaded: ${songHistory.value.length} songs.');
  }

  // This method accepts your full Song object and converts it to HistorySong for storage
  Future<void> addSongToHistory(Song song) async {
    final historySong = HistorySong.fromSong(song); // Convert the full Song to a lightweight HistorySong

    // Optional: Prevent adding the same song repeatedly if it's already the most recent
    if (songHistory.value.isNotEmpty &&
        songHistory.value.first.path == historySong.path &&
        songHistory.value.first.uri == historySong.uri) {
      debugPrint('Skipping adding duplicate song to history: ${historySong.title}');
      return;
    }

    await _historyBox.add(historySong); // Add the HistorySong object to the box
    _loadHistory(); // Reload history to update the ValueNotifier for UI
    debugPrint('Added song to history: ${historySong.title}. Total history: ${songHistory.value.length}');

    // Optional: Limit history size (e.g., keep only the last 100 songs)
    if (_historyBox.length > 100) {
      // Delete the oldest songs (Hive keys are typically sequential integers)
      final keysToDelete = _historyBox.keys.take(_historyBox.length - 100).toList();
      await _historyBox.deleteAll(keysToDelete);
      _loadHistory(); // Reload after pruning
      debugPrint('Pruned history. New total history: ${songHistory.value.length}');
    }
  }

  Future<void> clearHistory() async {
    await _historyBox.clear();
    _loadHistory(); // Clear the ValueNotifier as well
    debugPrint('Song history cleared.');
  }

  // Method to remove a specific song from history based on its data
  Future<void> removeSongFromHistory(HistorySong songToRemove) async {
    // Find the key of the song to remove. Iterate through values to find a match.
    // Note: This can be inefficient for very large lists. Consider adding a unique ID to HistorySong if performance becomes an issue.
    int? keyToDelete;
    for (var entry in _historyBox.toMap().entries) {
      if (entry.value.path == songToRemove.path &&
          entry.value.uri == songToRemove.uri &&
          entry.value.title == songToRemove.title) {
        keyToDelete = entry.key;
        break;
      }
    }

    if (keyToDelete != null) {
      await _historyBox.delete(keyToDelete);
      _loadHistory();
      debugPrint('Removed song from history: ${songToRemove.title}.');
    }
  }

  Future<void> dispose() async {
    await _historyBox.close(); // Close the Hive box when the service is no longer needed
    debugPrint('HistoryService disposed.');
  }
}