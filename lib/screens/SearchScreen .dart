// lib/screens/SearchScreen .dart
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/PlaybackService .dart';

class SongSearchScreen extends StatefulWidget {
  final List<Song> allSongs; // Receive all songs from the library

  const SongSearchScreen({super.key, required this.allSongs});

  @override
  State<SongSearchScreen> createState() => _SongSearchScreenState();
}

class _SongSearchScreenState extends State<SongSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Song> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchResults = List.from(widget.allSongs); // Initially show all songs
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _searchResults = widget.allSongs.where((song) {
        return song.title.toLowerCase().contains(query) ||
               (song.artist?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Songs'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title or artist...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged(); // Clear search results
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ),
        ),
      ),
      body: _searchResults.isEmpty && _searchController.text.isNotEmpty
          ? const Center(child: Text('No songs found matching your search.'))
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final song = _searchResults[index];
                return ListTile(
                  leading: song.albumArt != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            song.albumArt!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.music_note, size: 40),
                          ),
                        )
                      : const SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(child: Icon(Icons.music_note, size: 40)),
                        ),
                  title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(song.artist ?? 'Unknown Artist', maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    PlaybackService().playSong(song);
                    // Optionally pop back to previous screen after playing
                    // Navigator.pop(context);
                  },
                );
              },
            ),
    );
  }
}