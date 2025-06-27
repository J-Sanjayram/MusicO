import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:musico/models/song.dart';
import 'package:musico/screens/playlist_screen.dart';
import 'package:musico/services/playlist_service.dart';
import 'package:shimmer/shimmer.dart';
import '../services/PlaybackService .dart'; // Assuming this path is correct
import '../models/playlist.dart'; // Assuming this path is correct

import 'dart:async'; // Import for Timer
// Import for Uint8List

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart'; // Make sure you have this package imported

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

enum FilterType { songs, albums, artists, playlists }

class _SearchScreenState extends State<SearchScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  FilterType _selectedFilter = FilterType.songs;
  List<Track> _songResults = [];
  List<Album> _albumResults = [];
  List<Artist> _artistResults = [];
  List<Playlist> _playlistResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounce;
  bool _keyboardVisible = false;
  double _keyboardHeight = 0;

  // Assuming a fixed height for the NowPlayingBar for demonstration.
  // Ideally, this height would be passed in or derived dynamically if it changes.
  static const double _nowPlayingBarHeight = 70.0; // Adjust to your bar's actual height

  static const Color accentColor = Color.fromARGB(255, 255, 238, 0);
  static const Color textColor = Color(0xFFE0E0E0);
  static const Color primaryColor = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final newKeyboardVisible = bottomInset > 0;

    // Only update keyboard height if it's visible, otherwise set to 0.
    // This ensures _keyboardHeight correctly reflects the keyboard's presence.
    final currentKeyboardHeight = newKeyboardVisible ? bottomInset : 0.0;

    if (newKeyboardVisible != _keyboardVisible || (newKeyboardVisible && bottomInset != _keyboardHeight)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _keyboardVisible = newKeyboardVisible;
            _keyboardHeight = currentKeyboardHeight; // Update with the actual current height
          });
        }
      });
    }
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      _debounce?.cancel();
      setState(() {
        _songResults = [];
        _albumResults = [];
        _artistResults = [];
        _playlistResults = [];
        _errorMessage = null;
        _isLoading = false;
      });
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _songResults = [];
        _albumResults = [];
        _artistResults = [];
        _playlistResults = [];
        _errorMessage = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _songResults = [];
      _albumResults = [];
      _artistResults = [];
      _playlistResults = [];
    });

    try {
      switch (_selectedFilter) {
        case FilterType.songs:
          final results = await PlaylistService.fetchTracks(query);
          setState(() => _songResults = results);
          break;
        case FilterType.albums:
          final results = await PlaylistService.fetchAlbums(query);
          setState(() => _albumResults = results);
          break;
        case FilterType.artists:
          final results = await PlaylistService.fetchArtists(query);
          setState(() => _artistResults = results);
          break;
        case FilterType.playlists:
          final results = await PlaylistService.fetchPlaylists(query);
          setState(() => _playlistResults = results);
          break;
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to fetch results: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false, // Essential for our custom padding approach
      body: SafeArea(
        child: NestedScrollView(
          key: ValueKey(_selectedFilter),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                backgroundColor: Colors.black,
                elevation: 0,
                expandedHeight: 120.0,
                floating: true,
                pinned: true,
                snap: true,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: EdgeInsets.only(left: 16.0, bottom: 80),
                  title: AnimatedOpacity(
                    opacity: innerBoxIsScrolled ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Text(
                      'Search',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  background: Container(color: Colors.black),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60.0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(30.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) => _performSearch(value),
                        decoration: InputDecoration(
                          hintText: 'What do you want to listen to?',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Icon(Icons.search, color: Colors.grey[500]),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey[500]),
                                  onPressed: () {
                                    _searchController.clear();
                                    HapticFeedback.lightImpact();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 16.0),
                        cursorColor: accentColor,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildFilterChips(),
              ),
            ];
          },
          body: GestureDetector(
            onTap: () {
              if (_keyboardVisible) {
                _searchFocusNode.unfocus();
              }
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is UserScrollNotification && _keyboardVisible) {
                  _searchFocusNode.unfocus();
                }
                return false;
              },
              // The main content area. Its padding will be handled by the _buildContentArea() or _buildResultsList().
              child: _buildContentArea(),
            ),
          ),
        ),
      ),
    );
  }

  // --- Other Helper Widgets and Methods ---

  Widget _buildFilterChips() {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: FilterType.values.map((type) {
          final isSelected = _selectedFilter == type;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: ChoiceChip(
              label: Text(
                type.toString().split('.').last.capitalize(),
                style: TextStyle(
                  color: isSelected ? const Color.fromARGB(255, 10, 10, 10) : Colors.grey[400],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 8,
                ),
              ),
              selected: isSelected,
              selectedColor: accentColor.withOpacity(0.8),
              backgroundColor: Colors.grey[850],
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = type);
                  if (_searchController.text.isNotEmpty) {
                    _performSearch(_searchController.text);
                  }
                }
                HapticFeedback.lightImpact();
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? accentColor : Colors.grey[700]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContentArea() {
    // Calculate the total bottom padding dynamically.
    // It's the fixed bar height plus the keyboard height when visible.
    final double totalBottomPadding = _nowPlayingBarHeight + (_keyboardVisible ? _keyboardHeight : 0);

    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.only(bottom: totalBottomPadding), // Apply to shimmer as well
        child: _buildLoadingShimmer(),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: EdgeInsets.only(bottom: totalBottomPadding), // Apply to error as well
        child: _buildErrorState(_errorMessage!),
      );
    }

    if (_searchController.text.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: totalBottomPadding), // Apply to initial state as well
        child: _buildInitialSearchState(),
      );
    }

    return _buildResultsList(totalBottomPadding);
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[700]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0), // Base padding for shimmer items
        itemCount: 8,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: accentColor, size: 60),
            const SizedBox(height: 16),
            Text(
              'Oh no! There was an issue.',
              style: const TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _performSearch(_searchController.text);
                HapticFeedback.mediumImpact();
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Try Again', style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialSearchState() {
    return SingleChildScrollView( // Use SingleChildScrollView to allow scrolling if content overflows
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30,),
            Icon(Icons.search_rounded, size: 80, color: Colors.grey[700]),
            const SizedBox(height: 24),
            const Text(
              'Discover your next favorite song!',
              style: TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Search for tracks, albums, artists, or playlists.',
              style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _buildSuggestionChip('Top Tamil Hits'),
                  _buildSuggestionChip('Latest Releases'),
                  _buildSuggestionChip('Workout Mix'),
                  _buildSuggestionChip('Chill Vibes'),
                ],
              ),
            ),
            // Add extra space at the bottom of the initial state if needed,
            // though the padding on the parent _buildContentArea should handle it.
            // const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text, style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 14)),
      backgroundColor: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[700]!),
      ),
      onPressed: () {
        _searchController.text = text;
        _performSearch(text);
        _searchFocusNode.unfocus();
        HapticFeedback.lightImpact();
      },
    );
  }

  Widget _buildResultsList(double bottomPadding) {
    List<Widget> resultsWidgets;
    String emptyMessageType;

    switch (_selectedFilter) {
      case FilterType.songs:
        resultsWidgets = _songResults
            .map((track) => TrackTile(
                  track: track,
                  onTap: () => _playTrack(track),
                ))
            .toList();
        emptyMessageType = 'songs';
        break;
      case FilterType.albums:
        resultsWidgets = _albumResults
            .map((album) => AlbumTile(
                  album: album,
                  onTap: () => _viewAlbum(album),
                ))
            .toList();
        emptyMessageType = 'albums';
        break;
      case FilterType.artists:
        resultsWidgets = _artistResults
            .map((artist) => ArtistTile(
                  artist: artist,
                  onTap: () => _viewArtist(artist),
                ))
            .toList();
        emptyMessageType = 'artists';
        break;
      case FilterType.playlists:
        resultsWidgets = _playlistResults
            .map((playlist) => PlaylistTile(
                  playlist: playlist,
                  onTap: () => _viewPlaylist(playlist),
                ))
            .toList();
        emptyMessageType = 'playlists';
        break;
    }

    if (resultsWidgets.isEmpty && _searchController.text.isNotEmpty) {
      return _buildEmptyState(emptyMessageType);
    }

    // This ListView.builder's padding is crucial.
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding + 20), // Add 20 for extra buffer
      itemCount: resultsWidgets.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: resultsWidgets[index],
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    // Apply the same total bottom padding to the empty state view
    return SingleChildScrollView( // Allow scrolling for empty state if it's too tall
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied, size: 60, color: Colors.grey[700]),
            const SizedBox(height: 20),
            Text(
              'No $type found for "${_searchController.text}"',
              style: const TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching for something else or adjusting your filter.',
              style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playTrack(Track track) async {
    if (track.streamingUri.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(
          'This track cannot be played',
          Icons.error_outline,
          Colors.redAccent,
        ),
      );
      return;
    }

    try {
      Uint8List? albumArtBytes;
      if (track.image.isNotEmpty) {
        final response = await http.get(Uri.parse(track.image));
        if (response.statusCode == 200) {
          albumArtBytes = response.bodyBytes;
        }
      }

      final songToPlay = Song.fromUri(
        uri: track.streamingUri,
        title: track.title,
        artist: track.artistName,
        duration: track.durationMs,
        albumArt: albumArtBytes,
      );

      await PlaybackService().playSong(songToPlay);
      HapticFeedback.lightImpact();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(
          'Error playing song: ${e.toString()}',
          Icons.error_outline,
          Colors.redAccent,
        ),
      );
    }
  }

  void _viewAlbum(Album album) {
    final pseudoPlaylist = Playlist(
      id: album.id,
      title: album.title,
      image: album.image,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistTracksScreen(playlist: pseudoPlaylist),
      ),
    );
    HapticFeedback.lightImpact();
  }

  void _viewArtist(Artist artist) {
    ScaffoldMessenger.of(context).showSnackBar(
      _buildSnackBar(
        'Artist details for: ${artist.name}',
        Icons.person,
        accentColor,
      ),
    );
    HapticFeedback.lightImpact();
  }

  void _viewPlaylist(Playlist playlist) {
    ScaffoldMessenger.of(context).showSnackBar(
      _buildSnackBar(
        'Viewing playlist: ${playlist.title}',
        Icons.queue_music,
        accentColor,
      ),
    );
    HapticFeedback.lightImpact();
  }

  SnackBar _buildSnackBar(String message, IconData icon, Color color) {
    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(10),
    );
  }
}
extension StringCasingExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// --- Individual Tile Widgets for Search Results (No changes needed here) ---

class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  const TrackTile({super.key, required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
              child: CachedNetworkImage(
                imageUrl: track.image,
                height: 50,
                width: 50,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[800],
                  child: const Center(child: Icon(Icons.music_note, size: 28, color: Colors.grey)),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child: const Center(child: Icon(Icons.broken_image, size: 28, color: Colors.grey)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: const TextStyle(
                      color: _SearchScreenState.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.artistName.toString(),
                    style: TextStyle(
                      color: _SearchScreenState.textColor.withOpacity(0.7),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.play_circle_fill_rounded, color: _SearchScreenState.accentColor, size: 36),
          ],
        ),
      ),
    );
  }
}

class AlbumTile extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;
  const AlbumTile({super.key, required this.album, required this.onTap});

 
@override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.black, // Background color of the tile
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row( // Changed Column to Row for horizontal layout
        children: [
          // Column 1: Album Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: CachedNetworkImage(
              imageUrl: album.image,
              height: 90, // Adjusted size for list item (you can change this)
              width: 90,  // Adjusted size for list item
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[800],
                child: const Center(child: Icon(Icons.album, size: 30, color: Colors.grey)),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[800],
                child: const Center(child: Icon(Icons.broken_image, size: 30, color: Colors.grey)),
              ),
            ),
          ),
          const SizedBox(width: 12), // Space between image and text

          // Column 2: Album Title and Artist (using Expanded for flexible text)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
              mainAxisAlignment: MainAxisAlignment.center, // Center text vertically
              children: [
                Text(
                  album.title,
                  style: const TextStyle(
                    color: _SearchScreenState.textColor, // Assuming this is accessible
                    fontSize: 16, // Slightly larger for main title
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  album.id, // Assuming album.id is acting as the artist name here
                  style: TextStyle(
                    color: _SearchScreenState.textColor.withOpacity(0.7), // Assuming this is accessible
                    fontSize: 13, // Smaller for artist name
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}

class ArtistTile extends StatelessWidget {
  final Artist artist;
  final VoidCallback onTap;
  const ArtistTile({super.key, required this.artist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[800],
              backgroundImage: CachedNetworkImageProvider(artist.image),
              onBackgroundImageError: (exception, stacktrace) =>
                  const Icon(Icons.person, size: 50, color: Colors.grey),
              child: artist.image.isEmpty
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              artist.name,
              style: const TextStyle(
                color: _SearchScreenState.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              'Artist',
              style: TextStyle(
                color: _SearchScreenState.textColor.withOpacity(0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  const PlaylistTile({super.key, required this.playlist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: CachedNetworkImage(
                imageUrl: playlist.image,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[800],
                  child: const Center(child: Icon(Icons.queue_music, size: 40, color: Colors.grey)),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child: const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              playlist.title,
              style: const TextStyle(
                color: _SearchScreenState.textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (playlist.id != null && playlist.id!.isNotEmpty)
              Text(
                playlist.id!,
                style: TextStyle(
                  color: _SearchScreenState.textColor.withOpacity(0.7),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            if (playlist.id != null)
              Text(
                '${playlist.id} songs',
                style: TextStyle(
                  color: _SearchScreenState.textColor.withOpacity(0.7),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}


class TrackService {
  static Future<List<Track>> fetchTracks(String query, {int limit = 10}) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    if (query.isEmpty) return [];

    // Dummy data for demonstration
    return List.generate(limit, (index) => Track(
      id: 'track_$index',
      title: 'Song Title $index for "$query"',
      artistName: 'Artist Name $index',
      image: 'https://via.placeholder.com/150', // Placeholder image
      streamingUri: 'http://example.com/audio_$index.mp3',
      durationMs: (3 * 60 + index) * 1000,
    ));
  }
}