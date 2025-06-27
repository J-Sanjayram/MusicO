import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musico/services/lyrics_service.dart';
import '../models/song.dart';
import 'audio_handler_service.dart';
import 'dart:io'; // Required for File operations
import 'package:path_provider/path_provider.dart'; // Required for temporary directory

class PlaybackService {
  static final PlaybackService _instance = PlaybackService._internal();
  factory PlaybackService() => _instance;

  late final AudioPlayer _player;
  late final MyAudioHandler _handler;

  final ValueNotifier<Song?> currentSong = ValueNotifier(null);
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<Duration> currentPosition = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> totalDuration = ValueNotifier(Duration.zero);
final ValueNotifier<String?> currentRawLyrics = ValueNotifier<String?>(null);

  // ValueNotifier to hold the parsed synced lyrics
  final ValueNotifier<List<LyricsLine>> currentParsedLyrics = ValueNotifier<List<LyricsLine>>([]);

  // ValueNotifier for the currently playing song (you likely already have this)


  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  PlaybackService._internal() {
    _init();
  }

  Future<void> _init() async {
    _player = AudioPlayer();
  
    _handler = await AudioService.init(
      builder: () => MyAudioHandler(audioPlayer: _player),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.musico.channel.audio',
        androidNotificationChannelName: 'Musico Playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        // Ensure you have these capabilities if you want them to show
        // mediaButtons: [MediaButton.play, MediaButton.pause, MediaButton.skipToNext, MediaButton.skipToPrevious],
        // androidNotificationIcon: 'drawable/launch_background', // Optional: Custom notification icon
      ),
    );

    _player.playbackEventStream.listen((event) {
      isPlaying.value = _player.playing;
    });

    _player.positionStream.listen((position) {
      currentPosition.value = position;
    });

    _player.durationStream.listen((duration) {
      totalDuration.value = duration ?? Duration.zero;
    });

    _handler.mediaItem.listen((mediaItem) {
      debugPrint('AudioHandler received MediaItem update: ${mediaItem?.title}, Art URI: ${mediaItem?.artUri?.scheme}');
    });
  }

  Duration get position => currentPosition.value;
  Duration get duration => totalDuration.value;

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  // New helper function to save album art to a temporary file
  Future<Uri?> _saveAlbumArtToTempFile(Uint8List? albumArtBytes, String songId) async {
    if (albumArtBytes == null || albumArtBytes.isEmpty) {
      debugPrint("No album art bytes provided for saving.");
      return null;
    }
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/album_art_$songId.jpeg';
      final file = File(tempFilePath);
      await file.writeAsBytes(albumArtBytes);
      debugPrint("Album art saved to temporary file: $tempFilePath");
      return Uri.file(tempFilePath); // Return a file URI
    } catch (e) {
      debugPrint("Error saving album art to temporary file: $e");
      return null;
    }
  }


  List<LyricsLine> _parseLrcLyrics(String lrcContent) {
    List<LyricsLine> lyrics = [];
    // Regex for [mm:ss.xx] format, allowing for 2 or 3 digits for milliseconds
    final RegExp regExp = RegExp(r'^\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)$');

    for (String line in lrcContent.split('\n')) {
      final match = regExp.firstMatch(line.trim());
      if (match != null) {
        try {
          final int minutes = int.parse(match.group(1)!);
          final int seconds = int.parse(match.group(2)!);
          final String millisecondString = match.group(3)!;
          int milliseconds;
          if (millisecondString.length == 2) {
            milliseconds = int.parse(millisecondString) * 10; // Convert xx to xxx
          } else {
            milliseconds = int.parse(millisecondString);
          }

          final String text = match.group(4)!.trim();
          final Duration timestamp = Duration(
              minutes: minutes,
              seconds: seconds,
              milliseconds: milliseconds
          );
          lyrics.add(LyricsLine(timestamp, text));
        } catch (e) {
          debugPrint("Error parsing lyric line: '$line' - $e");
        }
      }
    }
    // Sort by timestamp just in case, although LRC files are usually sorted
    lyrics.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lyrics;
  }

  Future<void> playSong(Song song) async {
    currentSong.value = song;
    final String songIdentifier = song.path?.replaceAll(RegExp(r'[/\.]'), '_') ??
                                  song.uri?.replaceAll(RegExp(r'[/:.]'), '_') ??
                                  song.title.replaceAll(' ', '_');

    final Uri? albumArtUri = await _saveAlbumArtToTempFile(
      song.albumArt,
      songIdentifier,
    );

    // Clear previous lyrics immediately to show 'Loading lyrics...' state
    currentRawLyrics.value = null;
    currentParsedLyrics.value = [];

    try {
      final mediaItemId = song.path ?? song.uri!;

      final mediaItem = MediaItem(
        id: mediaItemId,
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: Duration(milliseconds: song.duration),
        artUri: albumArtUri,
      );

      if (song.path != null) {
        await _player.setFilePath(
          song.path!,
          tag: mediaItem,
        );
      } else if (song.uri != null) {
        await _player.setUrl(
          song.uri!,
          tag: mediaItem,
        );
      } else {
        debugPrint("Error: No path or URI provided for song. Cannot play.");
        return;
      }

      _handler.mediaItem.add(_player.sequenceState.currentSource?.tag as MediaItem?);

      // --- Start playing the song first ---
      await _player.play();
      // --- Song is now playing, proceed with lyrics in the background ---
      _fetchAndSetLyrics(song); // Call this without 'await'
    } catch (e) {
      debugPrint("Error playing song: $e");
      // Handle error, e.g., show a snackbar to the user
    }
  }

  // New private method to handle lyric fetching and parsing
  Future<void> _fetchAndSetLyrics(Song song) async {
    try {
      final String? fetchedLyrics = await LyricsService.fetchLyrics(song);

      // Only update if this is still the current song to avoid race conditions
      // if (song.path == currentSong.value?.path) { // Or a more robust song ID check
        currentRawLyrics.value = fetchedLyrics; // Store the raw fetched lyrics
        if (fetchedLyrics != null && fetchedLyrics.startsWith('[')) {
          currentParsedLyrics.value = _parseLrcLyrics(fetchedLyrics);
          debugPrint("Parsed ${currentParsedLyrics.value.length} synced lyric lines.");
        } else {
          debugPrint("Fetched plain lyrics or no synced lyrics found. Raw: ${fetchedLyrics ?? 'N/A'}");
        }
      // } else {
      //   debugPrint("Lyrics fetched for an old song, ignoring.");
      // }
    } catch (e) {
      debugPrint("Error fetching or parsing lyrics: $e");
      currentRawLyrics.value = "Failed to load lyrics."; // Show a message on UI
      currentParsedLyrics.value = []; // Ensure parsed lyrics are cleared
    }
  }
  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  void play() => _player.play();
  void pause() => _player.pause();

  void dispose() {
    _player.dispose();
    _handler.stop();
  }


  void forceLyricResync() {
  if (currentSong.value != null && currentParsedLyrics.value.isNotEmpty) {
    // We don't need to re-fetch lyrics, just notify the UI to re-sync its view.
    // The simplest way to trigger ValueListenableBuilder and its listeners
    // is to assign the same value again, but ValueNotifier usually doesn't notify
    // if the value is strictly identical.
    // So, we'll temporarily set it to a new list (even if content is same)
    // or trigger it through another means.
    // Forcing a "new" list will guarantee a notification.
    final List<LyricsLine> currentLyricsCopy = List.from(currentParsedLyrics.value);
    currentParsedLyrics.value = []; // Temporarily clear (or assign a different list instance)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      currentParsedLyrics.value = currentLyricsCopy; // Restore, triggering update
    });
    debugPrint("PlaybackService: Forced lyric resync notification.");
  } else if (currentSong.value != null && currentRawLyrics.value != null && currentParsedLyrics.value.isEmpty) {
     // If there are raw lyrics but no parsed (e.g., plain text), also trigger a refresh
     final String? rawLyricsCopy = currentRawLyrics.value;
     currentRawLyrics.value = null;
     WidgetsBinding.instance.addPostFrameCallback((_) {
       currentRawLyrics.value = rawLyricsCopy;
     });
     debugPrint("PlaybackService: Forced raw lyric resync notification.");
  }
}


  //static fetchAlbums(String query) {}
}