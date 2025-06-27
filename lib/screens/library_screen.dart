import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:musico/screens/SearchScreen .dart';
import '../models/song.dart';
import '../services/songs_provider.dart';
import '../services/audio_service.dart';
import 'dart:async';
import '../services/PlaybackService .dart';

enum LibraryView { playlists, artists, albums, allSongs }

class LibraryScreen extends StatefulWidget {
  final SongsProvider songsProvider;

  const LibraryScreen({super.key, required this.songsProvider});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final FocusNode _searchFocusNode = FocusNode();

  late List<Song> _cachedSongs;
  late List<String> allSongTitles;
  List<String> filteredSongTitles = [];

  List<Map<String, dynamic>> playlists = [
    {'name': 'Chill Vibes', 'songs': ['Song A', 'Song B']},
    {'name': 'Workout', 'songs': ['Song C', 'Song D']},
    {'name': 'Focus Music', 'songs': ['Song E', 'Song F', 'Song G']},
  ];

  List<Map<String, String?>> recentPlays = [];
  List<Map<String, String?>> favorites = [
    {'title': 'Favorite Song 1', 'artist': 'Artist 5'},
    {'title': 'Favorite Song 2', 'artist': 'Artist 6'},
  ];

  final TextEditingController _playlistNameController = TextEditingController();
  final TextEditingController _songSearchController = TextEditingController();
  List<String> selectedSongsForPlaylist = [];

  LibraryView _selectedView = LibraryView.playlists;

  @override
  void initState() {
    super.initState();
    _cachedSongs = List.from(widget.songsProvider.songs);
    allSongTitles = _cachedSongs.map((s) => s.title).toList();
    filteredSongTitles = List.from(allSongTitles);

    _populateRecentPlays();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _playlistNameController.dispose();
    _songSearchController.dispose();
    super.dispose();
  }

  void _populateRecentPlays() {
    recentPlays = _cachedSongs.take(5).map((song) => {
          'title': song.title,
          'artist': song.artist ?? 'Unknown Artist',
          'albumArt': song.albumArt != null ? 'local:${song.path}' : null,
        }).toList();
  }

  void _filterSongsForPlaylistModal() {
    setState(() {
      filteredSongTitles = allSongTitles
          .where((songTitle) => songTitle
              .toLowerCase()
              .contains(_songSearchController.text.toLowerCase()))
          .toList();
    });
  }

  void _showCreatePlaylistModal() {
    _playlistNameController.clear();
    _songSearchController.clear();
    selectedSongsForPlaylist.clear();
    filteredSongTitles = List.from(allSongTitles);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 30,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create New Playlist',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _playlistNameController,
              decoration: InputDecoration(
                labelText: 'Playlist Name',
                hintText: 'e.g., Morning Jams',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              ),
              cursorColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _songSearchController,
              decoration: InputDecoration(
                labelText: 'Search Songs to Add',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              ),
              onChanged: (_) => _filterSongsForPlaylistModal(),
              cursorColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            // Changed Expanded to SizedBox with a fixed height or a flexible height with constraints
            // to prevent overflow issues within the modal and ensure it behaves as expected
            SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.3, // Adjust height as needed
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredSongTitles.length,
                    itemBuilder: (ctx, idx) {
                      final songTitle = filteredSongTitles[idx];
                      final selected = selectedSongsForPlaylist.contains(songTitle);
                      return ListTile(
                        title: Text(
                          songTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        trailing: Checkbox(
                          value: selected,
                          onChanged: (bool? newValue) {
                            setModalState(() {
                              if (newValue == true) {
                                selectedSongsForPlaylist.add(songTitle);
                              } else {
                                selectedSongsForPlaylist.remove(songTitle);
                              }
                            });
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                        onTap: () {
                          setModalState(() {
                            if (selected) {
                              selectedSongsForPlaylist.remove(songTitle);
                            } else {
                              selectedSongsForPlaylist.add(songTitle);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_playlistNameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Playlist name cannot be empty!')),
                    );
                    return;
                  }
                  if (selectedSongsForPlaylist.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least one song!')),
                    );
                    return;
                  }
                  setState(() {
                    playlists.add({
                      'name': _playlistNameController.text.trim(),
                      'songs': List<String>.from(selectedSongsForPlaylist)
                    });
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Playlist "${_playlistNameController.text.trim()}" created!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save Playlist',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _toggleFavorite(String songTitle) {
    setState(() {
      favorites.removeWhere((fav) => fav['title'] == songTitle);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed "$songTitle" from favorites.')),
      );
    });
  }

  Future<void> _rescanLocalFiles() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scanning for new music...')),
    );

    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    final isAndroid13OrAbove = deviceInfo.version.sdkInt >= 33;
    final permission =
        isAndroid13OrAbove ? Permission.audio : Permission.storage;

    if (!await permission.request().isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied. Cannot rescan.')),
        );
      }
      return;
    }

    final newSongs = await AudioService.getSongs(forceRefresh: true);

    widget.songsProvider.updateSongs(newSongs);

    setState(() {
      _cachedSongs = List.from(newSongs);
      allSongTitles = _cachedSongs.map((s) => s.title).toList();
      filteredSongTitles = List.from(allSongTitles);
      _populateRecentPlays();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Found ${newSongs.length} songs. Music library updated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          // Use ClampingScrollPhysics to prevent overscrolling effects
          // that might interfere with app bar snapping/floating.
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverAppBar(
              //floating: true,
              pinned: true,
              //snap: true, // Keep snap for the desired effect
              expandedHeight: 120.0,
              toolbarHeight: kToolbarHeight,
              backgroundColor: theme.appBarTheme.backgroundColor,
              elevation: 0,
              titleSpacing: 0,
              flexibleSpace: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double currentHeight = constraints.biggest.height;
                  final double collapseProgress =
                      ((currentHeight - kToolbarHeight) / (120.0 - kToolbarHeight))
                          .clamp(0.0, 1.0);

                  final double titleFontSize =
                      Tween<double>(begin: 18.0, end: 28.0).transform(collapseProgress);

                  // Adjusted search bar opacity and offset for smoother transition
                  final double searchBarOpacity = collapseProgress;
                  final double searchBarOffset = 15 * (1 - collapseProgress);

                  return FlexibleSpaceBar(
                    // Set centerTitle to true if you want the title to be horizontally centered when collapsed
                    centerTitle: false, // Keeping false as per original intent
                    // Use a Stack to precisely position elements and avoid padding conflicts
                    titlePadding: EdgeInsets.zero, // Remove titlePadding from FlexibleSpaceBar
                    background: Container(
                      color: theme.appBarTheme.backgroundColor,
                    ),
                    title: Stack(
                      children: [
                        Positioned(
                          // Position the "Your Library" text
                          bottom: Tween<double>(begin: 12.0, end: 50.0).transform(collapseProgress), // Adjust bottom based on collapse progress
                          left: 16.0,
                          child: Opacity(
                            opacity: 1 - collapseProgress, // Fade out as it collapses if desired, or keep at 1
                            child: Text(
                              'Your Library',
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: theme.appBarTheme.titleTextStyle?.color ?? textTheme.titleLarge?.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Positioned(
                          // Position the search bar
                          bottom: Tween<double>(begin: 12.0, end: 12.0).transform(collapseProgress), // Keep consistent bottom margin
                          left: 16.0,
                          right: 16.0,
                          child: Opacity(
                            opacity: searchBarOpacity,
                            child: Transform.translate(
                              offset: Offset(0.0, searchBarOffset),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => SongSearchScreen(allSongs: widget.songsProvider.songs),
                                  ));
                                },
                                child: AbsorbPointer(
                                  child: Container(
                                    height: 30.0, // Increased height for better tap target
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.search, size: 15.0, color: Colors.grey[600]), // Slightly larger icon
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Search your library...',
                                              style: TextStyle(fontSize: 10.0, color: Colors.grey[600]), // Adjusted font size
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.grey),
                  tooltip: 'Rescan Music',
                  onPressed: _rescanLocalFiles,
                ),
                IconButton(
                  icon: const Icon(Icons.add_box_outlined, color: Colors.grey),
                  tooltip: 'Create New Playlist',
                  onPressed: _showCreatePlaylistModal,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<LibraryView>(
                    segments: const <ButtonSegment<LibraryView>>[
                      ButtonSegment<LibraryView>(
                        value: LibraryView.playlists,
                        label: Text('Playlists'),
                        icon: Icon(Icons.playlist_play),
                      ),
                      ButtonSegment<LibraryView>(
                        value: LibraryView.artists,
                        label: Text('Artists'),
                        icon: Icon(Icons.person),
                      ),
                      ButtonSegment<LibraryView>(
                        value: LibraryView.albums,
                        label: Text('Albums'),
                        icon: Icon(Icons.album),
                      ),
                      ButtonSegment<LibraryView>(
                        value: LibraryView.allSongs,
                        label: Text('Songs'),
                        icon: Icon(Icons.music_note),
                      ),
                    ],
                    selected: <LibraryView>{_selectedView},
                    onSelectionChanged: (Set<LibraryView> newSelection) {
                      setState(() {
                        _selectedView = newSelection.first;
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: Colors.amberAccent.withOpacity(0.1),
                      selectedForegroundColor: Colors.amberAccent,
                      foregroundColor: textTheme.bodyMedium?.color?.withOpacity(0.7),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
              ),
            ),
            _buildCurrentView(theme, textTheme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentView(ThemeData theme, TextTheme textTheme, ColorScheme colorScheme) {
    switch (_selectedView) {
      case LibraryView.playlists:
        return _buildPlaylistsView(theme, textTheme, colorScheme);
      case LibraryView.artists:
        return _buildArtistsView(theme, textTheme, colorScheme);
      case LibraryView.albums:
        return _buildAlbumsView(theme, textTheme, colorScheme);
      case LibraryView.allSongs:
        return _buildAllSongsView(theme, textTheme, colorScheme);
      default:
        return _buildPlaylistsView(theme, textTheme, colorScheme);
    }
  }

  Widget _buildPlaylistsView(ThemeData theme, TextTheme textTheme, ColorScheme colorScheme) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: playlists.isEmpty
          ? SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'No playlists yet. Create one to get started!',
                    style: textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final playlist = playlists[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: theme.cardColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.queue_music, size: 36, color: Colors.amberAccent),
                      title: Text(
                        playlist['name'],
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${(playlist['songs'] as List).length} songs',
                        style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Playing playlist: ${playlist['name']}')),
                        );
                      },
                    ),
                  );
                },
                childCount: playlists.length,
              ),
            ),
    );
  }

  Widget _buildArtistsView(ThemeData theme, TextTheme textTheme, ColorScheme colorScheme) {
    final List<String> artists = widget.songsProvider.songs.map((s) => s.artist ?? 'Unknown').toSet().toList();
    if (artists.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'No artists found. Scan your local files!',
              style: textTheme.bodyLarge?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final artistName = artists[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              color: theme.cardColor,
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person, size: 28),
                ),
                title: Text(artistName, style: textTheme.titleMedium),
                subtitle: Text(
                  '${widget.songsProvider.songs.where((s) => s.artist == artistName).length} songs',
                  style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Viewing artist: $artistName')),
                  );
                },
              ),
            );
          },
          childCount: artists.length,
        ),
      ),
    );
  }

  Widget _buildAlbumsView(ThemeData theme, TextTheme textTheme, ColorScheme colorScheme) {
    final Map<String, List<Song>> albumsMap = {};
    for (var song in widget.songsProvider.songs) {
      final albumKey = song.album ?? 'Unknown Album';
      if (!albumsMap.containsKey(albumKey)) {
        albumsMap[albumKey] = [];
      }
      albumsMap[albumKey]!.add(song);
    }
    final List<MapEntry<String, List<Song>>> albums = albumsMap.entries.toList();

    if (albums.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'No albums found. Scan your local files!',
              style: textTheme.bodyLarge?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final albumName = albums[index].key;
            final albumSongs = albums[index].value;
            final albumArt = albumSongs.firstWhere(
              (s) => s.albumArt != null,
              orElse: () => Song(path: '', title: '', artist: '', album: '', duration: 0, albumArt: null),
            ).albumArt;

            return GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Viewing album: $albumName')),
                );
              },
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: albumArt != null
                        ? Image.memory(
                            albumArt,
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: double.infinity,
                              height: 120,
                              color: Colors.grey[800],
                              child: const Icon(Icons.album, size: 50, color: Colors.grey),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            height: 120,
                            color: Colors.grey[800],
                            child: const Icon(Icons.album, size: 50, color: Colors.grey),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    albumName,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '${albumSongs.length} songs',
                    style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
          childCount: albums.length,
        ),
      ),
    );
  }

  Widget _buildAllSongsView(ThemeData theme, TextTheme textTheme, ColorScheme colorScheme) {
    return ValueListenableBuilder<List<Song>>(
      valueListenable: widget.songsProvider.songsNotifier,
      builder: (context, songs, _) {
        if (songs.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('No songs found on your device.', style: textTheme.bodyLarge?.copyWith(color: Colors.grey)),
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final song = songs[index];
              final bool isFavorite = favorites.any((fav) => fav['title'] == song.title && fav['artist'] == song.artist);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                color: Colors.transparent,
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: song.albumArt != null
                        ? Image.memory(
                            song.albumArt!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 48, height: 48, color: Colors.grey[800],
                              child: const Icon(Icons.music_note, size: 30, color: Colors.grey),
                            ),
                          )
                        : Container(
                            width: 48, height: 48, color: Colors.grey[800],
                            child: const Icon(Icons.music_note, size: 30, color: Colors.grey),
                          ),
                  ),
                  title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.titleMedium),
                  subtitle: Text(song.artist ?? 'Unknown Artist', maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                  trailing: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.pinkAccent : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isFavorite) {
                          favorites.removeWhere((fav) => fav['title'] == song.title && fav['artist'] == song.artist);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Removed "${song.title}" from favorites')));
                        } else {
                          favorites.add({'title': song.title, 'artist': song.artist ?? 'Unknown Artist'});
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added "${song.title}" to favorites')));
                        }
                      });
                    },
                  ),
                  onTap: () async {
                    await PlaybackService().playSong(song);
                  },
                ),
              );
            },
            childCount: songs.length,
          ),
        );
      },
    );
  }
}