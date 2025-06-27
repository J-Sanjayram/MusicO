import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import '../models/song.dart';
import 'package:path/path.dart' as p;

class AudioScanner {
  static final AudioScanner _instance = AudioScanner._internal();
  factory AudioScanner() => _instance;
  AudioScanner._internal();

  final _songController = StreamController<List<Song>>.broadcast();
  final _progressController = StreamController<double>.broadcast();

  Stream<List<Song>> get songStream => _songController.stream;
  Stream<double> get progressStream => _progressController.stream;

  Future<List<Song>> scanAudioFiles() async {
    final songs = <Song>[];
    final completer = Completer<List<Song>>();
    
    try {
      final receivePort = ReceivePort();
      await Isolate.spawn(_scanInIsolate, receivePort.sendPort);

      receivePort.listen((message) {
        if (message is List<Song>) {
          songs.addAll(message);
          _songController.add(List.from(songs));
        } else if (message is double) {
          _progressController.add(message);
        } else if (message == 'done') {
          completer.complete(songs);
          receivePort.close();
        }
      });
    } catch (e) {
      completer.completeError(e);
    }

    return completer.future;
  }

  static Future<void> _scanInIsolate(SendPort sendPort) async {
    final songs = <Song>[];
    final dirs = [
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
    ];

    int totalFiles = 0;
    int processedFiles = 0;

    // First count total files
    for (final dir in dirs) {
      final directory = Directory(dir);
      if (!await directory.exists()) continue;
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && _isAudioFile(entity.path)) {
          totalFiles++;
        }
      }
    }

    // Then process files
    for (final dir in dirs) {
      try {
        final directory = Directory(dir);
        if (!await directory.exists()) continue;

        await for (final entity in directory.list(recursive: true)) {
          if (entity is File && _isAudioFile(entity.path)) {
            try {
              final metadata = await MetadataRetriever.fromFile(entity);
              songs.add(Song(
                path: entity.path,
                title: metadata.trackName ?? p.basenameWithoutExtension(entity.path),
                artist: metadata.albumArtistName,
                album: metadata.albumName,
                duration: metadata.trackDuration ?? 0, // <-- This is required

                albumArt: metadata.albumArt,
              ));

              processedFiles++;
              sendPort.send(songs);
              sendPort.send(processedFiles / totalFiles);
            } catch (e) {
              debugPrint('Metadata error for ${entity.path}: $e');
              songs.add(Song.fromPath(entity.path));
            }
          }
        }
      } catch (e) {
        debugPrint('Error scanning directory $dir: $e');
      }
    }

    sendPort.send('done');
    Isolate.exit();
  }

  static bool _isAudioFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return ['.mp3', '.wav', '.aac', '.m4a', '.flac', '.ogg'].contains(ext);
  }

  void dispose() {
    _songController.close();
    _progressController.close();
  }
}
