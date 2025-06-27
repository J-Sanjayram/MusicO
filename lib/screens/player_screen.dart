import 'dart:async';

import 'package:flutter/material.dart';
import 'package:musico/screens/lyricpanel.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/song.dart';
import '../services/PlaybackService .dart'; // Ensure correct import path

import 'package:flutter/services.dart'; // Required for SystemChrome


// --- PlayerScreen ---
class PlayerScreen extends StatefulWidget {
  final Song song;
  const PlayerScreen({super.key, required this.song});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  // PlaybackService should ideally be provided via Provider or GetIt for better architecture,
  // but for this example, we'll instantiate it directly.
  final PlaybackService _playbackService = PlaybackService();
  Color _dominantColor = Colors.black;
  List<Color> _gradientColors = [Colors.black, Colors.black,Colors.transparent];

  @override
  void initState() {
    super.initState();
    // Play the song only if it's different from the currently playing one
    if (_playbackService.currentSong.value?.path != widget.song.path) {
      _playbackService.playSong(widget.song);
    }
    // Update color after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateDominantColor();
    });
  }

  @override
  void didUpdateWidget(covariant PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update color if the song changes
    if (oldWidget.song.path != widget.song.path) {
      _updateDominantColor();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set system UI overlay style when dependencies change (e.g., theme)
    //_setSystemUIOverlayStyle();
  }

  @override
  void dispose() {
    // Reset system UI overlay style when screen is disposed
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
    //   statusBarColor: Colors.transparent,
    //   systemNavigationBarColor: Colors.black,
    //   systemNavigationBarIconBrightness: Brightness.light,
    // ));
    // It's crucial to dispose of PlaybackService if it's managed by this widget
    // For a global service, it would be managed outside.
    // _playbackService.dispose(); // Uncomment if PlaybackService has a dispose method and lifecycle is tied here.
    super.dispose();
  }

  /// Sets the system UI overlay style based on the dominant color.
  void _setSystemUIOverlayStyle() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: _dominantColor.withOpacity(0.8),
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  /// Extracts dominant color from album art and updates gradient colors.
  // In _PlayerScreenState class
Future<void> _updateDominantColor() async {
  Color newDominantColor = Colors.black; // Default to black
  List<Color> newGradientColors = [Colors.black, Colors.black];

  if (widget.song.albumArt != null) {
    final imageProvider = MemoryImage(widget.song.albumArt!);
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(100, 100),
      );

      // Prioritize dark vibrant/muted colors, or blend with black
      newDominantColor = palette.darkVibrantColor?.color ??
                         palette.darkMutedColor?.color ??
                         palette.vibrantColor?.color.withOpacity(0.7) ?? // Make vibrant a bit darker
                         palette.dominantColor?.color.withOpacity(0.7) ?? // Make dominant a bit darker
                         Colors.black; // Ensure it's dark if no other suitable color is found

      newGradientColors = [
        newDominantColor, // Start with the (now potentially darker) dominant color
        Colors.black.withOpacity(0.9),
        Colors.black,
      ];
    } catch (e) {
      debugPrint('Error generating palette: $e');
    }
  }

  if (_dominantColor != newDominantColor || _gradientColors != newGradientColors) {
    setState(() {
      _dominantColor = newDominantColor;
      _gradientColors = newGradientColors;
    });
   // _setSystemUIOverlayStyle();
  }
}
  @override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final double screenWidth = MediaQuery.of(context).size.width;
  final double albumArtSquareSize = screenWidth - (20.0 * 2);

  return Scaffold(
    backgroundColor: Colors.transparent, // Background handled by the Container's gradient
    extendBodyBehindAppBar: true, // Allows body to extend behind the AppBar
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down, size: 30),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Now Playing', style: TextStyle(fontSize: 10)),
      centerTitle: true,
    ),
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _gradientColors,
          stops: const [0.0, 0.6, 1.0], // Adjust stops for gradient effect
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Spacer for status bar and app bar
              SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 10),

              // --- Visual Block (Album Art + Lyrics) ---
              SizedBox(
                height: albumArtSquareSize + (albumArtSquareSize * 0.2), // Adjusted height for lyrics overlay
                width: screenWidth,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                                      Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: albumArtSquareSize,
                    child: ShaderMask( // <--- Wrap the Hero with ShaderMask
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white, // Fully opaque at the top
                            Colors.white, // Fully opaque for most of the image
                            Colors.transparent, // Start fading to transparent
                          ],
                          stops: const [0.0, 0.3, 0.89], // Adjust these stops for fade control
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn, // This blend mode applies the mask
                      child: Opacity( // <--- Keep Opacity here if you want overall transparency
                        opacity: 0.9,
                        child: Hero(
                          tag: 'album_art_${widget.song.path}',
                          child:Container(
                            decoration: BoxDecoration(
                            shape: BoxShape.circle, // Match the ClipOval's shape
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5), // Shadow color
                                spreadRadius: 0, // How much the shadow expands
                                blurRadius: 15, // How blurry the shadow is
                                offset: Offset(0,- 6), // X and Y offset of the shadow
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: widget.song.albumArt != null
                                ? Image.memory(widget.song.albumArt!, fit: BoxFit.cover)
                                : Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.music_note, size: 120, color: Colors.white),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                                      ),

                    // Fading effect at the bottom of the album art (fades into transparent)
                    // Positioned(
                    //   bottom: 0,
                    //   left: 0,
                    //   right: 0,
                    //   height: albumArtSquareSize * 0.2, // Adjust the fade area
                    //   child: Container(
                    //     // decoration: BoxDecoration(
                    //     //   gradient: LinearGradient(
                    //     //     begin: Alignment.topCenter,
                    //     //     end: Alignment.bottomCenter,
                    //     //     colors: [
                    //     //       Colors.black.withOpacity(0.8), // Start with a dark color (visible)
                    //     //       Colors.transparent, // End with transparency
                    //     //     ],
                    //     //     stops: const [0.0, 1.0], // Control fade
                    //     //   ),
                    //     // ),
                    //   ),
                    // ),
                    // Lyrics Display Widget positioned over the album art
                    Positioned(
                      bottom: albumArtSquareSize * 0.10, // Position higher from the bottom
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 105.0, // Fixed height for the visible lyric area
                        child: LyricsDisplayWidget(
                          songService: _playbackService,
                          enableUserScrolling: false, // Prevents user from scrolling lyrics
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- Song Title & Artist ---
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0, left: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: widget.song.albumArt != null
                          ? Image.memory(widget.song.albumArt!, width: 50, height: 50, fit: BoxFit.cover)
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.music_note, size: 30, color: Colors.white),
                            ),
                    ),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.song.title,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.song.artist ?? 'Unknown Artist',
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // --- Progress Bar ---
              _buildProgressBar(theme),

              const SizedBox(height: 10),

              // --- Playback Controls ---
              _buildPlaybackControls(theme),

              const SizedBox(height: 30),

              // --- Extra Scrollable Content ---
             // Text("Lyrics Info", style: theme.textTheme.titleMedium),
              const SizedBox(height: 20),
              FullLyricsPanel(playbackService: _playbackService,),

              const SizedBox(height: 40),

              const Center(
                child: Text("Mu𝄞icO...", style: TextStyle(fontSize: 10, color: Colors.grey)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
  );
}

  /// Builds the progress bar for the song.
  Widget _buildProgressBar(ThemeData theme) {
    return SizedBox(
      width: double.infinity, // Occupy full width
      child: StreamBuilder<Duration>(
        stream: _playbackService.positionStream,
        builder: (context, snapshot) {
          final position = snapshot.data ?? Duration.zero;
          final totalDuration = _playbackService.totalDuration.value;

          double sliderValue = totalDuration.inMilliseconds > 0
              ? position.inMilliseconds.toDouble() / totalDuration.inMilliseconds.toDouble()
              : 0.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2.0,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                  activeTrackColor:Colors.white,
                  inactiveTrackColor: Colors.grey.withOpacity(0.3),
                  thumbColor: Colors.white,
                  overlayColor: theme.colorScheme.primary.withOpacity(0.15),
                ),
                child: Slider(
                  min: 0.0,
                  max: 1.0,
                  value: sliderValue.clamp(0.0, 1.0), // Ensure value is within bounds
                  onChanged: (newValue) {
                    final newPosition = Duration(milliseconds: (newValue * totalDuration.inMilliseconds).round());
                    _playbackService.seek(newPosition);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(position), style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                    Text(_formatDuration(totalDuration), style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds the playback control buttons.
  Widget _buildPlaybackControls(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(icon: const Icon(Icons.shuffle, size: 30), onPressed: () {}),
        IconButton(icon: const Icon(Icons.skip_previous, size: 40), onPressed: () {}),
        ValueListenableBuilder<bool>(
          valueListenable: _playbackService.isPlaying,
          builder: (context, isPlaying, _) {
            return IconButton(color: Colors.white,
              icon: Icon(
                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                size: 72,
              ),
              onPressed: _playbackService.togglePlayPause,
            );
          },
        ),
        IconButton(icon: const Icon(Icons.skip_next, size: 40), onPressed: () {}),
        IconButton(icon: const Icon(Icons.repeat, size: 30), onPressed: () {}),
      ],
    );
  }

  /// Formats a Duration object into a "MM:SS" string.
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}




class FullLyricsDisplayWidget extends StatelessWidget {
  final String lyrics; // The full lyrics text

  const FullLyricsDisplayWidget({
    super.key,
    required this.lyrics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If lyrics are empty or null, show a message
    if (lyrics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            'No lyrics available for this song.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lyrics',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            lyrics,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5, // Adjust line height for readability
              color: Colors.white70,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
// --- LyricsDisplayWidget ---

/// A widget that displays song lyrics and automatically scrolls to the current line.
class LyricsDisplayWidget extends StatefulWidget {
  final PlaybackService songService;
  final bool enableUserScrolling; // Controls if the user can manually scroll

  const LyricsDisplayWidget({
    super.key,
    required this.songService,
    this.enableUserScrolling = true, // Default to true, but PlayerScreen sets it to false
  });

  @override
  State<LyricsDisplayWidget> createState() => _LyricsDisplayWidgetState();
}

class _LyricsDisplayWidgetState extends State<LyricsDisplayWidget> {
  int _currentLyricIndex = -1;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _positionSubscription;

  // Map to store GlobalKeys for each lyric line, enabling precise scrolling
  final Map<int, GlobalKey> _lyricKeys = {};

  @override
  void initState() {
    super.initState();

    // Listen to changes in playback position to update current lyric
    _positionSubscription = widget.songService.positionStream.listen((position) {
      if (mounted) {
        _updateCurrentLyricIndex(position);
      }
    });

    // Listen to changes in parsed lyrics (e.g., when a new song loads)
    widget.songService.currentParsedLyrics.addListener(_onLyricsChanged);

    // Initial sync of lyric index after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCurrentLyricIndex(widget.songService.position);
    });
  }

  @override
  void didUpdateWidget(covariant LyricsDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the song service instance changes, re-subscribe to its streams/notifiers
    if (oldWidget.songService != widget.songService) {
      _positionSubscription?.cancel();
      oldWidget.songService.currentParsedLyrics.removeListener(_onLyricsChanged);

      _positionSubscription = widget.songService.positionStream.listen((position) {
        if (mounted) {
          _updateCurrentLyricIndex(position);
        }
      });
      widget.songService.currentParsedLyrics.addListener(_onLyricsChanged);
      _onLyricsChanged(); // Immediately update on new lyrics
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    widget.songService.currentParsedLyrics.removeListener(_onLyricsChanged);
    _scrollController.dispose();
    _lyricKeys.clear(); // Clear keys to prevent memory leaks
    super.dispose();
  }

  /// Called when the parsed lyrics change (e.g., a new song is loaded).
  /// Resets the current lyric index and scroll position.
  void _onLyricsChanged() {
    if (!mounted) return;
    setState(() {
      _currentLyricIndex = -1; // Reset index
      _lyricKeys.clear(); // Clear keys for new lyrics
    });

    // Reset scroll position if the controller has clients
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }

    // Force update after layout to ensure correct initial scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCurrentLyricIndex(widget.songService.position);
    });
  }

  /// Updates the `_currentLyricIndex` based on the current playback position.
  void _updateCurrentLyricIndex(Duration currentPosition) {
    if (!mounted) return;

    final parsedLyrics = widget.songService.currentParsedLyrics.value;
    if (parsedLyrics.isEmpty) {
      if (_currentLyricIndex != -1) {
        setState(() {
          _currentLyricIndex = -1;
        });
      }
      return;
    }

    int newIndex = -1;
    for (int i = 0; i < parsedLyrics.length; i++) {
      // Find the last lyric line whose timestamp is less than or equal to current position
      if (currentPosition >= parsedLyrics[i].timestamp) {
        newIndex = i;
      } else {
        break; // Lyrics are sorted by timestamp, so we can stop early
      }
    }

    // Only update state and scroll if the current lyric index has changed
    if (newIndex != _currentLyricIndex) {
      setState(() {
        _currentLyricIndex = newIndex;
      });

      if (newIndex != -1) {
        // Schedule scroll to new lyric line after the frame is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToIndex(newIndex);
        });
      }
    } else {
      // This is a subtle but important optimization:
      // If the index hasn't changed but the widget rebuilt,
      // and we are currently on a lyric, try to scroll again.
      // This helps in cases where the initial scroll might have been imperfect
      // due to layout timings.
      if (newIndex != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToIndex(newIndex);
        });
      }
    }
  }

  /// Scrolls the `ListView` to center the lyric at the given `index`.
  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) {
      debugPrint("LyricsDisplayWidget: ScrollController has no clients yet.");
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final RenderBox? lyricBox = _lyricKeys[index]?.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? listViewBox = context.findRenderObject() as RenderBox?;

      if (lyricBox == null || listViewBox == null) {
        debugPrint("LyricsDisplayWidget: Could not get RenderBox for lyric item or ListView. Falling back to estimated scroll.");
        // Fallback: If render boxes aren't available (e.g., item not yet rendered or off-screen),
        // use an estimation to scroll. This is less precise but robust.
        const double estimatedLineHeight = 40.0; // Average height of a lyric line
        final double targetOffset = (index * estimatedLineHeight) -
            (_scrollController.position.viewportDimension / 2) +
            (estimatedLineHeight / 2);

        final double safeOffset = targetOffset.clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        );

        _scrollController.animateTo(
          safeOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        return;
      }

      // Calculate the position of the lyric item relative to the top of the ListView's viewport
      final double lyricTopRelativeToListView = lyricBox.localToGlobal(Offset.zero, ancestor: listViewBox).dy;
      final double lyricHeight = lyricBox.size.height;
      final double viewportHeight = _scrollController.position.viewportDimension;

      // Calculate the desired scroll offset to center the lyric in the viewport.
      // This formula ensures the center of the current lyric line aligns with the center of the viewport.
      final double targetScrollOffset = _scrollController.position.pixels +
          lyricTopRelativeToListView -
          (viewportHeight / 2) +
          (lyricHeight / 2);

      // Clamp the offset to ensure it stays within the actual scrollable bounds
      final double safeOffset = targetScrollOffset.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );

      debugPrint("LyricsDisplayWidget: Scrolling lyric #$index. Current Pixels: ${_scrollController.position.pixels}, Target Offset: $targetScrollOffset, Safe Offset: $safeOffset");

      _scrollController.animateTo(
        safeOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ).then((_) {
        debugPrint("LyricsDisplayWidget: Scroll animation for lyric #$index completed. Final Pixels: ${_scrollController.position.pixels}");
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<List<LyricsLine>>(
      valueListenable: widget.songService.currentParsedLyrics,
      builder: (context, parsedLyrics, child) {
        // Display raw lyrics or loading message if parsed lyrics are empty
        if (parsedLyrics.isEmpty) {
          return ValueListenableBuilder<String?>(
            valueListenable: widget.songService.currentRawLyrics,
            builder: (context, rawLyrics, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    rawLyrics ?? "Loading LRC...",
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          );
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: parsedLyrics.length,
          // Control user scrolling based on `enableUserScrolling` property
          physics: widget.enableUserScrolling
              ? const BouncingScrollPhysics() // Allows user to scroll with bounce effect
              : const ClampingScrollPhysics(), // Prevents user scrolling, only programmatic scrolling
          itemBuilder: (context, index) {
            final isCurrent = index == _currentLyricIndex;
            // Ensure a GlobalKey exists for each lyric line for accurate measurement
            _lyricKeys.putIfAbsent(index, () => GlobalKey());

            final lyricText = parsedLyrics[index].text;

            final lyricStyle = theme.textTheme.headlineSmall?.copyWith(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              fontSize: isCurrent ? 18 : 10,
              color: isCurrent
                  ? Colors.white // Highlight current lyric
                  : Colors.white60,
            );

            Widget lyricContent;
            if (isCurrent && lyricText.trim().isEmpty) {
              // Display a music note icon for an empty current lyric line (e.g., instrumental breaks)
              lyricContent = Icon(
                Icons.music_note,
                color: lyricStyle?.color,
                size: (lyricStyle?.fontSize ?? 16) + 4,
              );
            } else {
              lyricContent = Text(
                lyricText,
                key: _lyricKeys[index], // Attach the GlobalKey to the Text widget
                style: lyricStyle,
                textAlign: TextAlign.center,
              );
            }

            return Align(
              alignment: Alignment.center, // Center the lyric text horizontally
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: lyricContent,
              ),
            );
          },
        );
      },
    );
  }
}

// @override
// Widget build(BuildContext context) {
//   final theme = Theme.of(context);

//   return Scaffold(
//     backgroundColor: theme.scaffoldBackgroundColor,
//     appBar: AppBar(
//       backgroundColor: Colors.transparent, // Transparent app bar
//       elevation: 0,
//       leading: IconButton(
//         icon: const Icon(Icons.keyboard_arrow_down, size: 30),
//         onPressed: () => Navigator.pop(context),
//       ),
//       title: const Text('Now Playing', style: TextStyle(fontSize: 15)),
//       centerTitle: true,
//     ),
//     body: Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center, // Center the Column's children
//         children: [
//           const SizedBox(height: 10),

//           // --- MODIFIED SECTION START ---
//           // Use a Stack to layer the large album art and the info row
//           Stack(
//             alignment: Alignment.bottomCenter, // Aligns content within the stack to the bottom center
//             children: [
//               // 1. Large Album Art with ShaderMask for fade effect
//               Hero(
//                 tag: 'album_art_${widget.song.path}',
//                 child: ShaderMask(
//                   shaderCallback: (rect) {
//                     return LinearGradient(
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                       colors: [
//                         Colors.black,
//                         Colors.black,
//                         Colors.black.withOpacity(0.0), // Starts fading out near the bottom
//                       ],
//                       stops: const [0.0, 0.7, 1.0], // Adjust stops for fade intensity and position
//                     ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
//                   },
//                   blendMode: BlendMode.dstIn, // This blend mode keeps the destination's alpha values
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(16),
//                     child: widget.song.albumArt != null
//                         ? Image.memory(
//                             widget.song.albumArt!,
//                             width: MediaQuery.of(context).size.width * 0.8,
//                             height: MediaQuery.of(context).size.width * 0.8,
//                             fit: BoxFit.cover,
//                           )
//                         : Container(
//                             width: MediaQuery.of(context).size.width * 0.8,
//                             height: MediaQuery.of(context).size.width * 0.8,
//                             decoration: BoxDecoration(
//                               color: Colors.grey[800],
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             child: const Icon(Icons.music_note, size: 120, color: Colors.white),
//                           ),
//                   ),
//                 ),
//               ),

//               // 2. The compact Row positioned at the bottom of the Stack
//               Positioned(
//                 bottom: 10, // Adjust this value to control how far up from the bottom of the album art it appears
//                 left: 0,
//                 right: 0,
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20.0), // Add horizontal padding for the row
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min, // Keep the row size minimal, but allow centering
//                     mainAxisAlignment: MainAxisAlignment.center, // THIS CENTERS THE CONTENT OF THE ROW
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(4),
//                         child: widget.song.albumArt != null
//                             ? Image.memory(
//                                 widget.song.albumArt!,
//                                 width: 50,
//                                 height: 50,
//                                 fit: BoxFit.cover,
//                               )
//                             : Container(
//                                 width: 50,
//                                 height: 50,
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey[800],
//                                   borderRadius: BorderRadius.circular(4),
//                                 ),
//                                 child: const Icon(Icons.music_note, size: 25, color: Colors.white),
//                               ),
//                       ),
//                       const SizedBox(width: 15), // Spacing between album art and text
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Text(
//                               widget.song.title,
//                               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             Text(
//                               widget.song.artist ?? 'Unknown Artist',
//                               style: const TextStyle(fontSize: 14, color: Colors.white70),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           // --- MODIFIED SECTION END ---

//           // Removed the separate Song Title and Artist Text widgets here,
//           // as their information is now displayed on the album art.
//           // You can uncomment them if you want both.
//           // const SizedBox(height: 16),
//           // Text(
//           //   widget.song.title,
//           //   style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
//           //   textAlign: TextAlign.center,
//           //   maxLines: 2,
//           //   overflow: TextOverflow.ellipsis,
//           // ),
//           // const SizedBox(height: 8),
//           // Text(
//           //   widget.song.artist ?? 'Unknown Artist',
//           //   style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
//           //   textAlign: TextAlign.center,
//           //   maxLines: 1,
//           //   overflow: TextOverflow.ellipsis,
//           // ),

//           const Spacer(flex: 2),
//           // Progress Bar and Time
//           _buildProgressBar(theme),
//           const SizedBox(height: 6),
//           // Playback Controls
//           _buildPlaybackControls(theme),
//           const Spacer(flex: 2),
//         ],
//       ),
//     ),
//   );
// }