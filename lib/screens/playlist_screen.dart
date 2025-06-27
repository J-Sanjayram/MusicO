import 'package:flutter/material.dart';
import 'package:musico/services/PlaybackService%20.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/playlist_service.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:palette_generator/palette_generator.dart'; // Import this

class PlaylistTracksScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistTracksScreen({super.key, required this.playlist});

  @override
  State<PlaylistTracksScreen> createState() => _PlaylistTracksScreenState();
}

class _PlaylistTracksScreenState extends State<PlaylistTracksScreen> {
  late Future<List<Track>> _tracksFuture;
  String? _currentPlayingTrackId;
  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 0.0;
  Color _backgroundGradientColor = Colors.black; // Initial dark color

  static const Color primaryColor = Color(0xFF1A1A2E);
  static const Color accentColor = Color(0xFFE94560);
  static const Color textColor = Color(0xFFE0E0E0);
  static const Color cardColor = Color(0xFF282846);
  static const Color spotifyGreen = Color.fromRGBO(69, 83, 233, 1);

  @override
  void initState() {
    super.initState();
    _tracksFuture = PlaylistService.fetchTracksForAlbum(widget.playlist.id);
    _scrollController.addListener(_onScroll);
    _updateBackgroundColorFromImage(); // Call this to set the background color
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    const double scrollThreshold = 200.0; // Adjust based on your header size
    setState(() {
      _appBarOpacity = (_scrollController.offset / scrollThreshold).clamp(0.0, 1.0);
    });
  }

  Future<void> _updateBackgroundColorFromImage() async {
    if (widget.playlist.image.isNotEmpty) {
      try {
        final PaletteGenerator paletteGenerator = await PaletteGenerator.fromImageProvider(
          NetworkImage(widget.playlist.image),
          size: const Size(100, 100), // Smaller size for faster processing
        );
        setState(() {
          // Prefer a dark vibrant color, otherwise a dominant color, fallback to black
          _backgroundGradientColor = paletteGenerator.darkVibrantColor?.color ??
              paletteGenerator.dominantColor?.color ??
              Colors.black;
        });
      } catch (e) {
        debugPrint('Error generating palette from image: $e');
        setState(() {
          _backgroundGradientColor = primaryColor; // Fallback to primary color
        });
      }
    } else {
      setState(() {
        _backgroundGradientColor = primaryColor; // Fallback if no image
      });
    }
  }

  String _formatDuration(int? durationMs) {
    if (durationMs == null || durationMs <= 0) return '0:00';
    final int minutes = durationMs ~/ 60000;
    final int seconds = (durationMs % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column( // Changed from Column to Row
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // This section now handles the title and play button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distributes space
                    children: [
                      Expanded( // Allows text to take available space
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // This is the main playlist title that is always visible below the header
                            // Only show this title when the app bar title is mostly hidden
                            Opacity(
                              opacity: 1.0 - _appBarOpacity, // Fades out as app bar title fades in
                              child: Text(
                                widget.playlist.title,
                                style: const TextStyle(
                                  color: textColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2, // Allow title to wrap
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Created by ${widget.playlist.id ?? 'Unknown Artist'}',
                              style: TextStyle(
                                color: textColor.withOpacity(0.7),
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16), // Space between text and button
                      _buildPlayButton(), // Moved the play button here
                    ],
                  ),
                  const SizedBox(height: 20), // Spacing below this row
                ],
              ),
            ),
          ),
          FutureBuilder<List<Track>>(
            future: _tracksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: accentColor),
                  ),
                );
              } else if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Error loading tracks: ${snapshot.error}',
                      style: const TextStyle(color: textColor),
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No tracks found for this playlist.',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                );
              }

              final tracks = snapshot.data!;

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = tracks[index];
                    final isPlaying = _currentPlayingTrackId == track.id;
                    return _buildTrackListItem(track, isPlaying);
                  },
                  childCount: tracks.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      backgroundColor: _backgroundGradientColor, // Start transparent
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: textColor),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Opacity(
        opacity: _appBarOpacity,
        child: Text(
          widget.playlist.title,
          style: const TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,fontSize: 20
          ),
          maxLines: 1, // Ensure title in app bar doesn't wrap
          overflow: TextOverflow.ellipsis,
        ),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _backgroundGradientColor.withOpacity(0.8), // Top of gradient from album art
                Colors.black, // Darker bottom to blend with the list
              ],
              stops: const [0.0, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: widget.playlist.image.isNotEmpty
                          ? Image.network(
                              widget.playlist.image,
                              height: 200,
                              width: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.music_note,
                                size: 100,
                                color: Colors.grey[600],
                              ),
                            )
                          : Icon(
                              Icons.music_note,
                              size: 100,
                              color: Colors.grey[600],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
          StretchMode.fadeTitle,
        ],
      ),
    );
  }

  // Renamed _buildPlayButtonRow to _buildPlayButton as it's now just the button
  Widget _buildPlayButton() {
    return ElevatedButton( // Changed from ElevatedButton.icon
      onPressed: () {
        _tracksFuture.then((tracks) {
          if (tracks.isNotEmpty) {
            _playTrack(tracks.first);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No tracks to play!')),
            );
          }
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: spotifyGreen, // Vibrant color
        shape: const CircleBorder(), // Circular shape
        padding: const EdgeInsets.all(0), // Adjust padding for icon size
        minimumSize: const Size(60, 60), // Set a fixed size for the circular button
        elevation: 10, // Add some shadow for a "popping" effect
        shadowColor: spotifyGreen.withOpacity(0.6), // Shadow matching the button color
      ),
      child: const Icon(Icons.play_arrow, color: Colors.black, size: 35), // Larger icon
    );
  }

  Widget _buildTrackListItem(Track track, bool isPlaying) {
    return Card(
      color: const Color.fromARGB(0, 40, 40, 70),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _playTrack(track),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: track.image.isNotEmpty
                    ? Image.network(
                        track.image,
                        height: 50,
                        width: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.music_note,
                          size: 50,
                          color: Colors.grey[600],
                        ),
                      )
                    : Icon(
                        Icons.music_note,
                        size: 50,
                        color: Colors.grey[600],
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: TextStyle(
                        color: isPlaying ? spotifyGreen : textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      track.artistName.toString(),
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatDuration(track.durationMs),
                style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Color.fromARGB(255, 189, 183, 183)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('More options for ${track.title}')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _playTrack(Track track) async {
    if (track.streamingUri.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('This track does not have a streaming URL.')),
      );
      return;
    }

    Uint8List? albumArtBytes;
    if (track.image.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(track.image));
        if (response.statusCode == 200) {
          albumArtBytes = response.bodyBytes;
        }
      } catch (e) {
        debugPrint('Error downloading album art for ${track.title}: $e');
      }
    }

    final songToPlay = Song.fromUri(
      uri: track.streamingUri,
      title: track.title,
      artist: track.artistName,
      album: null,
      duration: track.durationMs,
      albumArt: albumArtBytes,
    );

    try {
      await PlaybackService().playSong(songToPlay);
      setState(() {
        _currentPlayingTrackId = track.id;
      });
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Now playing: ${track.title}')),
      // );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error playing song.')),
        );
      }
    }
  }
}