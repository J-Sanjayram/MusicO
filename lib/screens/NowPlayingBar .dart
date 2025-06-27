import 'package:flutter/material.dart';
import '../services/PlaybackService .dart'; // Corrected import path/spacing
import '../models/song.dart';
import '../screens/player_screen.dart'; // Ensure this import is correct

class NowPlayingBar extends StatefulWidget {
  const NowPlayingBar({super.key});

  @override
  State<NowPlayingBar> createState() => _NowPlayingBarState();
}

class _NowPlayingBarState extends State<NowPlayingBar> {
  // Access the singleton instance of PlaybackService
  final PlaybackService _playback = PlaybackService();

  @override
  Widget build(BuildContext context) {
    // Listen to currentSong updates to show/hide the bar
    return ValueListenableBuilder<Song?>(
      valueListenable: _playback.currentSong,
      builder: (context, song, _) {
        if (song == null) {
          return const SizedBox.shrink(); // Hide the bar if no song is playing
        }

        return GestureDetector(
          onTap: () {
            // Navigate to the PlayerScreen when the bar is tapped
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => PlayerScreen(song: song),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0); // Start from bottom
                  const end = Offset.zero; // End at current position
                  const curve = Curves.easeOutCubic; // Smooth acceleration and deceleration

                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              //border: const Border(top: BorderSide(width: 0.4, color: Colors.grey)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Song info and controls
                Row(
                  children: [
                    // Album Art with animation (AnimatedSwitcher for smooth transitions)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                      child: ClipRRect(
                        key: ValueKey(song.albumArt?.hashCode ?? song.path), // Key for animation
                        borderRadius: BorderRadius.circular(8),
                        child: song.albumArt != null
                            ? Image.memory(song.albumArt!, width: 48, height: 48, fit: BoxFit.cover)
                            : Container(
                                width: 48,
                                height: 48,
                                color: Colors.grey[700],
                                child: const Icon(Icons.music_note, size: 30, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Song Title & Artist
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            song.artist ?? 'Unknown',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Play/Pause button, listening to isPlaying state
                    ValueListenableBuilder<bool>(
                      valueListenable: _playback.isPlaying,
                      builder: (context, isPlaying, _) {
                        return IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 36,
                          ),
                          onPressed: _playback.togglePlayPause, // Call toggle method
                        );
                      },
                    ),
                  ],
                ),
                // Progress bar
                ValueListenableBuilder<Duration>(
                  valueListenable: _playback.currentPosition,
                  builder: (context, currentPosition, _) {
                    final totalDuration = _playback.totalDuration.value; // Get total duration
                    double progress = totalDuration.inMilliseconds > 0
                        ? currentPosition.inMilliseconds / totalDuration.inMilliseconds
                        : 0.0;
                    return LinearProgressIndicator(
                      value: progress,
                      minHeight: 2,
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}