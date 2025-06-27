// import 'dart:isolate';
// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:path/path.dart' as p;
// import 'package:flutter_media_metadata/flutter_media_metadata.dart';
// import '../models/song.dart';

// class FileScanner {
//   static Future<List<Song>> scanAudioFiles(List<String> paths) async {
//     final receivePort = ReceivePort();
//     await Isolate.spawn(_scanFiles, [receivePort.sendPort, paths]);
    
//     final List<Song> songs = await receivePort.first;
//     return songs;
//   }

//   static void _scanFiles(List<dynamic> args) async {
//     SendPort sendPort = args[0];
//     List<String> paths = args[1];
//     List<Song> songs = [];

//     try {
//       for (String path in paths) {
//         final dir = Directory(path);
//         if (!await dir.exists()) continue;

//         await for (var entity in dir.list(recursive: true)) {
//           if (entity is! File) continue;
//           if (_isAudioFile(entity.path)) {
//             songs.add(await _createSongFromFile(entity));
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('Error scanning files: $e');
//     }

//     Isolate.exit(sendPort, songs);
//   }

//   static bool _isAudioFile(String path) {
//     final ext = p.extension(path).toLowerCase();
//     return ['.mp3', '.wav', '.aac', '.m4a', '.flac', '.ogg'].contains(ext);
//   }

//   static Future<Song> _createSongFromFile(File file) async {
//     try {
//       final metadata = await MetadataRetriever.fromFile(file);
//       return Song(
//       path: file.path,
//       title: metadata.trackName ?? p.basenameWithoutExtension(file.path),
//       artist: metadata.albumArtistName,
//       album: metadata.albumName,
//       albumArt: metadata.albumArt,
//       duration: metadata.trackDuration ?? 0, // <-- This is required
//     );
//     } catch (_) {
//       return Song.fromPath(file.path);
//     }
//   }
// }
