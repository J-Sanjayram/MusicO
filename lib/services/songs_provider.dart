import 'package:flutter/material.dart';
import '../models/song.dart';

class SongsProvider extends ChangeNotifier {
  List<Song> _songs = [];

  List<Song> get songs => _songs;

  // Added a ValueNotifier for better listening directly in widgets if preferred
  ValueNotifier<List<Song>> songsNotifier = ValueNotifier([]);

  void updateSongs(List<Song> newSongs) {
    _songs = newSongs;
    notifyListeners(); // Notify listeners that the song list has changed
    songsNotifier.value = newSongs; // Update the ValueNotifier too
  }
}