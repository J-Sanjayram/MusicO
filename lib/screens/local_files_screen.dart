import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_kit/media_kit.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final Player _player = Player();
  final List<Media> _tracks = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  int? _currentlyPlayingIndex;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    // Check and request storage permission
    var permission = await Permission.storage.status;
    if (!permission.isGranted) {
      permission = await Permission.storage.request();
    }
    
    // For Android 13+ we need different permissions
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      final audioPermission = await Permission.audio.status;
      if (!audioPermission.isGranted) {
        await Permission.audio.request();
      }
    }

    setState(() {
      _hasPermission = permission.isGranted;
    });

    if (_hasPermission) {
      _fetchMediaFiles();
    }
  }

  Future<void> _fetchMediaFiles() async {
    try {
      // This is a simplified approach - in a real app you'd need to:
      // 1. Use the file_picker or file_selector package to get directories
      // 2. Recursively scan directories for audio files
      // 3. Create Media objects for each file
      
      // For demonstration, we'll simulate finding files
      await Future.delayed(const Duration(seconds: 1)); // Simulate loading
      
      final simulatedTracks = [
        Media('file:///storage/emulated/0/Music/song1.mp3'),
        Media('file:///storage/emulated/0/Music/song2.mp3'),
        Media('file:///storage/emulated/0/Music/song3.mp3'),
      ];

      setState(() {
        _tracks.addAll(simulatedTracks);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching media: ${e.toString()}')),
      );
    }
  }

  Future<void> _playTrack(int index) async {
    try {
      await _player.open(Playlist(_tracks));
      await _player.jump(index);
      await _player.play();
      
      setState(() {
        _currentlyPlayingIndex = index;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing track: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_off, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              const Text('Storage permission required'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkAndRequestPermissions,
                child: const Text('Grant Permission'),
              ),
              TextButton(
                onPressed: openAppSettings,
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_tracks.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_note, size: 64, color: Colors.grey),
              const SizedBox(height: 20),
              const Text('No tracks found'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchMediaFiles,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Local Music',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Rescan',
              onPressed: _fetchMediaFiles,
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: _tracks.length,
        itemBuilder: (context, index) {
          final uri = _tracks[index].uri;
          final fileName = uri.split('/').last;
          
          return ListTile(
            leading: const Icon(Icons.music_note, size: 48),
            title: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Local file',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: _currentlyPlayingIndex == index
                ? const Icon(Icons.equalizer, color: Colors.deepPurple)
                : null,
            onTap: () => _playTrack(index),
          );
        },
      ),
    );
  }
}