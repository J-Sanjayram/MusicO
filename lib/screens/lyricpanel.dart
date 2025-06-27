import 'package:flutter/material.dart';
import 'package:musico/models/song.dart'; // Ensure this path is correct
import 'package:musico/services/PlaybackService%20.dart';
import 'dart:async'; // For Timer

// Assume LyricsLine is defined somewhere, e.g., in models/lyrics_line.dart
// For demonstration purposes if it's not defined elsewhere:


class FullLyricsPanel extends StatefulWidget {
  final PlaybackService playbackService;

  const FullLyricsPanel({
    Key? key,
    required this.playbackService,
  }) : super(key: key);

  @override
  State<FullLyricsPanel> createState() => _FullLyricsPanelState();
}

class _FullLyricsPanelState extends State<FullLyricsPanel> {
  final ScrollController _scrollController = ScrollController(); // Keep for manual user scrolling
  List<LyricsLine> _parsedLyrics = [];
  String? _rawLyrics;
  int _currentLineIndex = -1; // Still used for highlighting synced lyrics

  late Color textColor; // Defined for consistent theme usage

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    textColor = Theme.of(context).colorScheme.secondary;
  }

  @override
  void initState() {
    super.initState();
    _parsedLyrics = widget.playbackService.currentParsedLyrics.value;
    _rawLyrics = widget.playbackService.currentRawLyrics.value;

    widget.playbackService.currentParsedLyrics.addListener(_onParsedLyricsChanged);
    widget.playbackService.currentRawLyrics.addListener(_onRawLyricsChanged);
    // RE-ENABLE THIS LISTENER: This is crucial for updating the highlight index
    widget.playbackService.currentPosition.addListener(_updateCurrentLyricHighlight);
  }

  @override
  void dispose() {
    widget.playbackService.currentParsedLyrics.removeListener(_onParsedLyricsChanged);
    widget.playbackService.currentRawLyrics.removeListener(_onRawLyricsChanged);
    // REMOVE THIS LISTENER: Corresponding removal
    widget.playbackService.currentPosition.removeListener(_updateCurrentLyricHighlight);
    _scrollController.dispose();
    super.dispose();
  }

  void _onParsedLyricsChanged() {
    if (!mounted) return;
    setState(() {
      _parsedLyrics = widget.playbackService.currentParsedLyrics.value;
      _rawLyrics = null;
      _currentLineIndex = -1; // Reset highlight
    });
    // No automatic scroll call here
  }

  void _onRawLyricsChanged() {
    if (!mounted) return;
    setState(() {
      _rawLyrics = widget.playbackService.currentRawLyrics.value;
      _currentLineIndex = -1; // Reset highlight if raw lyrics change
    });
  }

  // METHOD TO UPDATE HIGHLIGHT INDEX (NO SCROLLING)
  void _updateCurrentLyricHighlight() {
    if (!mounted || _parsedLyrics.isEmpty) return;

    final currentSongPosition = widget.playbackService.currentPosition.value;

    int newIndex = -1;
    for (int i = 0; i < _parsedLyrics.length; i++) {
      if (currentSongPosition >= _parsedLyrics[i].timestamp) {
        if (i == _parsedLyrics.length - 1 ||
            currentSongPosition < _parsedLyrics[i + 1].timestamp) {
          newIndex = i;
          break;
        }
      }
    }

    // Only update state if the index has changed to avoid unnecessary rebuilds
    if (_currentLineIndex != newIndex) {
      setState(() {
        _currentLineIndex = newIndex;
      });
      // IMPORTANT: ABSOLUTELY NO _scrollController.animateTo() CALLS HERE.
      // And no debugPrints related to "Scrolling lyric #".
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget lyricsContent;
    if (_parsedLyrics.isNotEmpty) {
      lyricsContent = ListView.builder(
        controller: _scrollController,
        itemCount: _parsedLyrics.length,
        itemBuilder: (context, index) {
          final isCurrentLine = index == _currentLineIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: theme.textTheme.bodyLarge!.copyWith(
                color: isCurrentLine ? textColor : Colors.white70,
                fontWeight: isCurrentLine ? FontWeight.bold : FontWeight.normal,
                fontSize: 20,
              ),
              child: Text(
                _parsedLyrics[index].text.isEmpty ? ' ' : _parsedLyrics[index].text,
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      );
    } else if (_rawLyrics != null && _rawLyrics!.trim().isNotEmpty) {
      List<String> plainLines = _rawLyrics!.split('\n').where((line) => line.trim().isNotEmpty).toList();
      lyricsContent = ListView.builder(
        controller: _scrollController,
        itemCount: plainLines.length,
        itemBuilder: (context, index) {
          final isCurrentLine = false; // Always false for plain lyrics
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: theme.textTheme.bodyLarge!.copyWith(
                color: isCurrentLine ? Colors.blueGrey[200] : Colors.white70,
                fontWeight: isCurrentLine ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
              child: Text(
                plainLines[index].isEmpty ? ' ' : plainLines[index],
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      );
    } else {
      lyricsContent = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              widget.playbackService.currentSong.value != null
                  ? "Loading lyrics..."
                  : "No song playing.",
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54),
            ),
            if (widget.playbackService.currentSong.value != null)
              TextButton(
                onPressed: () {
                  debugPrint("Retry Loading Lyrics button pressed (functionality needs to be added to PlaybackService).");
                },
                child: Text("Retry Loading Lyrics", style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
              ),
          ],
        ),
      );
    }

    final double estimatedLineHeight = 24.0;
    final double minLyricsHeight = estimatedLineHeight * 5;
    final double maxLyricsHeight = estimatedLineHeight * 15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            "Full Lyrics",
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 30),
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: minLyricsHeight,
            maxHeight: maxLyricsHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.1, 0.9, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: lyricsContent,
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}