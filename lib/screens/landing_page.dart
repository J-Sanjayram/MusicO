import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:musico/screens/playlist_screen.dart';
import 'package:musico/services/PlaybackService%20.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';
import '../models/song.dart'; // Import your Song model
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
// Assuming PlaylistService contains fetchTracks


// Ensure your LandingPage reflects the AppBar changes (no title text)
class LandingPage extends StatelessWidget {
  final void Function(int)? onItemTapped;

  const LandingPage({super.key, this.onItemTapped});

  // Define colors consistent with MainNavigationScreen
  static const Color primaryColor = Color.fromARGB(255, 240, 216, 31);
  static const Color accentColor = Color.fromARGB(255, 255, 221, 0);
  static const Color textColor = Color(0xFFE0E0E0);
  static const Color cardColor = Color(0xFF282846);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Consistent dark background
      body: SafeArea( // Ensures content is not obscured by device UI elements (notch, status bar)
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(), // Provides a pleasing scroll bounce effect
          slivers: [
            // Replaced AnimatedAppBarContent with a more detailed AnimatedHeaderContent
            _AnimatedHeaderContent(
              onItemTapped: onItemTapped,
              primaryColor: primaryColor,
              accentColor: accentColor,
              textColor: textColor,
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Uniform horizontal padding for all content
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    const SizedBox(height: 70), // Increased vertical spacing below the header

                    // Top Tracks Section
                    _buildSectionHeader(context, 'Quick Tracks'),
                    //const SizedBox(height: 12), // Consistent spacing after header
                    SizedBox(
                      height: 270, // Retained height, ensure TopTracksGrid fits well
                      child: TopTracksGrid(
                        cardColor: cardColor,
                        primaryColor: primaryColor,
                        accentColor: accentColor,
                      ),
                    ),

                    const SizedBox(height: 40), // More generous spacing between major content sections

                    // Featured Section
                    _buildSectionHeader(context, 'Featured'),
                    //const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: FeaturedMusicGrid(cardColor: cardColor),
                    ),

                    const SizedBox(height: 40),

                    // Playlists Section
                    _buildSectionHeader(context, 'Playlists'),
                    //const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: PlaylistsGrid(cardColor: cardColor),
                    ),

                    const SizedBox(height: 40),

                    // Recommended Section
                    _buildSectionHeader(context, 'Recommended'),
                    //const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: RecommendedTracksGrid(accentColor: accentColor),
                    ),

                    const SizedBox(height: 32), // Padding at the very bottom
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a standard section header for content categories.
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0), // Small padding below the text itself
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 26, // Slightly increased font size for prominence
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 1.2, // Improved letter spacing for better readability
        ),
      ),
    );
  }

  // NOTE: _buildCustomGridItem is not directly used in this LandingPage's build method.
  // It should be part of the individual grid widgets (e.g., TopTracksGrid's item builder)
  // if it's meant to define the appearance of individual items.
  Widget _buildCustomGridItem(BuildContext context, String title, IconData iconData) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10.0), // Slightly more rounded corners for a softer look
        boxShadow: [ // Subtle shadow for depth
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.8), // Slightly transparent primary color for a layered effect
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    bottomLeft: Radius.circular(10.0),
                  ),
                ),
                child: Icon(
                  iconData,
                  color: accentColor,
                  size: 36, // Larger icon for better visual impact
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0), // Increased horizontal padding for text
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 17, // Slightly larger font size for title
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// A dedicated widget for the animated and interactive header content.
class _AnimatedHeaderContent extends StatelessWidget {
  final void Function(int)? onItemTapped;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;

  const _AnimatedHeaderContent({
    required this.onItemTapped,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180.0,
      // floating: true, // REMOVED
      pinned: true,
      // snap: true,      // REMOVED
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor.withOpacity(0.1), primaryColor.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: FlexibleSpaceBar(
            centerTitle: false,
            titlePadding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 9,),
                  Text(
                    _getGreeting(),
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome Back!',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 16,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.search, color: textColor),
                        onPressed: () {
                          print('Search tapped!');
                        },
                        tooltip: 'Search',
                      ),
                      IconButton(
                        icon: Icon(Icons.notifications, color: textColor),
                        onPressed: () {
                          print('Notifications tapped!');
                        },
                        tooltip: 'Notifications',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    // Current time is Thursday, June 26, 2025 at 2:11:51 PM IST.
    // So hour is 14
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }
}
// Re-using the FeaturedMusicGrid, PlaylistsGrid, and RecommendedTracksGrid
// with colors passed down from LandingPage or MainNavigationScreen
class FeaturedMusicGrid extends StatefulWidget {
  final Color cardColor; // Base color, but less prominent in this design
  // Assuming these colors are consistent with LandingPage and MainNavigationScreen
  static const Color accentColor = Color(0xFFE94560);
  static const Color textColor = Color(0xFFE0E0E0);
  static const Color primaryColor = Color(0xFF1A1A2E);

  const FeaturedMusicGrid({super.key, required this.cardColor});

  @override
  State<FeaturedMusicGrid> createState() => _FeaturedMusicGridState();
}

class _FeaturedMusicGridState extends State<FeaturedMusicGrid> {
  late Future<List<Album>> _albumsFuture;

  @override
  void initState() {
    super.initState();
    _albumsFuture = PlaylistService.fetchFeaturedAlbums('Old Tamil');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Album>>(
      future: _albumsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer(); // Shimmer for the new design
        } else if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final albums = snapshot.data!;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          // Allow shadows and overlaps
          clipBehavior: Clip.none,
          itemCount: albums.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            final album = albums[index];
            return _buildFeaturedAlbumCard(album); // New unique style for featured
          },
        );
      },
    );
  }

  /// Builds a unique "hero" style card for featured albums.
  Widget _buildFeaturedAlbumCard(Album album) {
    final double cardWidth = 180; // Wider card for hero feel
    final double imageHeight = 180; // Image takes most of the height

    return GestureDetector(
      onTap: () {
        // HapticFeedback.lightImpact(); // Uncomment for haptic feedback
        print('Tapped on featured album: ${album.title}');
        // TODO: Navigate to album details or start playing
      },
      child: Container(
        width: cardWidth,
        height: imageHeight, // Explicitly match the SizedBox height from LandingPage
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              spreadRadius: 2,
              blurRadius: 15, // More blur for a softer, glowing shadow
              offset: const Offset(0, 8), // More offset for greater depth
            ),
          ],
        ),
        child: Stack(
          children: [
            // Album Artwork (main visual)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: album.image,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[800],
                    child: Center(
                        child: CircularProgressIndicator(
                            color: FeaturedMusicGrid.accentColor.withOpacity(0.5))),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[800],
                    child: Icon(Icons.broken_image, size: 60, color: Colors.grey[600]),
                  ),
                ),
              ),
            ),

            // Gradient Overlay for Text Readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.7), // Stronger opacity at bottom
                      Colors.black.withOpacity(0.2), // Lighter in middle
                      Colors.transparent // Transparent at top
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.4, 0.8], // Control gradient spread
                  ),
                ),
              ),
            ),

            // Text Content (Title, Artist, Genre)
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: FeaturedMusicGrid.textColor,
                    ),
                  )
                ],
              ),
            ),

            // Play Button Overlay
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                 // color: FeaturedMusicGrid.accentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: FeaturedMusicGrid.accentColor.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                  onPressed: () {
                    // HapticFeedback.mediumImpact(); // Stronger feedback for action button
                    print('Play button tapped for: ${album.title}');
                    // TODO: Implement direct playback functionality
                  },
                  tooltip: 'Play Album',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a shimmer loading effect for the featured grid items.
  Widget _buildLoadingShimmer() {
  final double cardWidth = 180;
  final double imageHeight = 180;

  return ListView.separated(
    scrollDirection: Axis.horizontal,
    clipBehavior: Clip.none,
    itemCount: 2, // Show a couple of shimmer items
    separatorBuilder: (_, __) => const SizedBox(width: 16),
    itemBuilder: (context, index) {
      return Shimmer.fromColors(
        // Ensure widget.cardColor is accessible in the scope where this function is defined
        baseColor: widget.cardColor.withOpacity(0.7),
        highlightColor: widget.cardColor.withOpacity(0.2),
        child: Container(
          width: cardWidth,
          height: imageHeight,
          // Removed the direct 'color' property from this Container
          decoration: BoxDecoration(
            color: Colors.white, // The color is correctly inside BoxDecoration
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Placeholder for image
              Positioned.fill(
                child: Container(
                  // Moved 'color' inside BoxDecoration for this Container
                  decoration: BoxDecoration(
                    color: Colors.white, // Color is now correctly inside decoration
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              // Placeholder for text
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // These Containers are fine as they only have 'color' and no 'decoration'
                    Container(height: 18, width: 140, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(height: 14, width: 100, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(height: 12, width: 80, color: Colors.white),
                  ],
                ),
              ),
              // Placeholder for play button
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 44, // Size of the IconButton
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white, // Color is correctly inside decoration
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  /// Builds an informative error state message.
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: FeaturedMusicGrid.accentColor, size: 48),
            const SizedBox(height: 12),
            Text(
              'Failed to load featured music.',
              style: const TextStyle(color: FeaturedMusicGrid.textColor, fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Please check your connection and try again.',
              style: TextStyle(color: FeaturedMusicGrid.textColor.withOpacity(0.7), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            // Optional: Retry button
            // const SizedBox(height: 16),
            // ElevatedButton.icon(
            //   onPressed: () {
            //     setState(() {
            //       _albumsFuture = PlaylistService.fetchFeaturedAlbums('Top Tamil'); // Re-fetch data
            //     });
            //   },
            //   icon: Icon(Icons.refresh, color: Colors.white),
            //   label: Text('Try Again', style: TextStyle(color: Colors.white)),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: FeaturedMusicGrid.accentColor,
            //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  /// Builds a user-friendly message for when no content is available.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_outline, color: FeaturedMusicGrid.textColor.withOpacity(0.6), size: 48),
            const SizedBox(height: 12),
            Text(
              'No featured albums right now.',
              style: TextStyle(color: FeaturedMusicGrid.textColor.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Check back soon for new highlights!',
              style: TextStyle(color: FeaturedMusicGrid.textColor.withOpacity(0.6), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


class PlaylistsGrid extends StatefulWidget {
  final Color cardColor; // The base background color for items
  // Assuming these colors are consistent with LandingPage and MainNavigationScreen
  static const Color accentColor = Color(0xFFE94560);
  static const Color textColor = Color(0xFFE0E0E0);
  static const Color primaryColor = Color(0xFF1A1A2E); // Need primary color for gradients/shadows

  const PlaylistsGrid({super.key, required this.cardColor});

  @override
  State<PlaylistsGrid> createState() => _PlaylistsGridState();
}

class _PlaylistsGridState extends State<PlaylistsGrid> {
  late Future<List<Playlist>> _playlistsFuture;

  @override
  void initState() {
    super.initState();
    _playlistsFuture = PlaylistService.fetchPlaylists("tamil");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Playlist>>(
      future: _playlistsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer();
        } else if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final playlists = snapshot.data!;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          // Crucial for the layered effect's shadows/transforms
          clipBehavior: Clip.none,
          itemCount: playlists.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return _buildPlaylistStackCard(playlist); // New unique style
          },
        );
      },
    );
  }

  /// Builds a unique "stacked" playlist card.
  Widget _buildPlaylistStackCard(Playlist playlist) {
    // Base image size
    final double imageSize = 130;
    // Offset for the stacked effect
    final double stackOffset = 10;

    return GestureDetector(
      onTap: () {
        // HapticFeedback.lightImpact(); // Uncomment for haptic feedback
        print('Tapped on playlist: ${playlist.title}');
        // TODO: Navigate to playlist details
      },
      // Ensure the whole area is tappable and gives visual feedback
      child: Container(
        width: imageSize + (stackOffset * 2), // Adjust width to accommodate stack effect
        // Added some height to ensure text fits
        height: 180, // Matches the height constraint from LandingPage
        child: Stack(
          alignment: Alignment.bottomCenter, // Align content to the bottom
          children: [
            // Layer 3 (Bottom) - Farthest back, smallest offset
            Positioned(
              left: stackOffset * 2,
              bottom: stackOffset * 2,
              child: _buildStackedImagePlaceholder(imageSize, PlaylistsGrid.primaryColor.withOpacity(0.3)),
            ),
            // Layer 2 (Middle)
            Positioned(
              left: stackOffset,
              bottom: stackOffset,
              child: _buildStackedImagePlaceholder(imageSize, PlaylistsGrid.primaryColor.withOpacity(0.6)),
            ),
            // Layer 1 (Top) - The actual playlist image with content
            Positioned(
              left: 0,
              top: 0, // Position at the top to allow stacking below
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CachedNetworkImage(
                    imageUrl: playlist.image,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                      child: Center(child: CircularProgressIndicator(color: PlaylistsGrid.accentColor.withOpacity(0.5))),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
                    ),
                  ),
                ),
              ),
            ),
            // Text Overlay (Title & Details)
            Positioned(
              bottom: 0, // Align to the very bottom
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                // Optional: A subtle gradient backdrop for text readability
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: PlaylistsGrid.textColor,
                      ),
                    ),
                    Text(
                      '${playlist.id} songs', // Display track count
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        color: PlaylistsGrid.textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to build the background stacked layers.
  Widget _buildStackedImagePlaceholder(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }


  /// Builds a shimmer loading effect for the grid items.
  Widget _buildLoadingShimmer() {
    // Shimmer effect for the stacked card
    final double imageSize = 130;
    final double stackOffset = 10;
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      itemCount: 3, // Show 3 shimmer cards
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: widget.cardColor.withOpacity(0.7),
          highlightColor: widget.cardColor.withOpacity(0.2),
          child: Container(
            width: imageSize + (stackOffset * 2),
            height: 180,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  left: stackOffset * 2,
                  bottom: stackOffset * 2,
                  child: Container(
                    width: imageSize,
                    height: imageSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                Positioned(
                  left: stackOffset,
                  bottom: stackOffset,
                  child: Container(
                    width: imageSize,
                    height: imageSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: imageSize,
                    height: imageSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 16, width: 100, color: Colors.white),
                        const SizedBox(height: 4),
                        Container(height: 12, width: 70, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  /// Builds an informative error state message.
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: PlaylistsGrid.accentColor, size: 48),
            const SizedBox(height: 12),
            Text(
              'Failed to load playlists.',
              style: const TextStyle(color: PlaylistsGrid.textColor, fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Please check your connection and try again.',
              style: TextStyle(color: PlaylistsGrid.textColor.withOpacity(0.7), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            // Optional: Retry button
            // const SizedBox(height: 16),
            // ElevatedButton.icon(
            //   onPressed: () {
            //     setState(() {
            //       _playlistsFuture = PlaylistService.fetchPlaylists();
            //     });
            //   },
            //   icon: Icon(Icons.refresh, color: Colors.white),
            //   label: Text('Retry', style: TextStyle(color: Colors.white)),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: PlaylistsGrid.accentColor,
            //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  /// Builds a user-friendly message for when no content is available.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_play, color: PlaylistsGrid.textColor.withOpacity(0.6), size: 48),
            const SizedBox(height: 12),
            Text(
              'No playlists found.',
              style: TextStyle(color: PlaylistsGrid.textColor.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Create your first playlist!',
              style: TextStyle(color: PlaylistsGrid.textColor.withOpacity(0.6), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            // Optional: Call to action button
            // const SizedBox(height: 16),
            // ElevatedButton.icon(
            //   onPressed: () {
            //     // TODO: Navigate to create playlist screen
            //   },
            //   icon: Icon(Icons.add, color: Colors.white),
            //   label: Text('New Playlist', style: TextStyle(color: Colors.white)),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: PlaylistsGrid.accentColor,
            //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}


class RecommendedTracksGrid extends StatelessWidget {
  final Color accentColor;
  const RecommendedTracksGrid({super.key, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1A1A2E);

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 7,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (context, index) => ActionChip(
        label: Text(
          'Track ${index + 1}',
          style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: accentColor.withOpacity(0.8),
        elevation: 3,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        onPressed: () {
          print('Tapped on recommended track: Track ${index + 1}');
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
    );
  }
}



class TopTracksGrid extends StatefulWidget {
  final Color cardColor;
  final Color primaryColor;
  final Color accentColor;

  const TopTracksGrid({
    super.key,
    required this.cardColor,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  State<TopTracksGrid> createState() => _TopTracksGridState();
}

class _TopTracksGridState extends State<TopTracksGrid> {
  late Future<List<Track>> _topTracksFuture;
  static const Color textColor = Color(0xFFE0E0E0); // For consistency

  @override
  void initState() {
    super.initState();
    _topTracksFuture = PlaylistService.fetchTracks('New Tamil Songs');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Track>>(
      future: _topTracksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer();
        } else if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final tracks = snapshot.data!;

        // Group tracks into chunks of 4 for vertical columns
        List<List<Track>> groupedTracks = [];
        for (int i = 0; i < tracks.length; i += 4) {
          groupedTracks.add(
            tracks.sublist(i, (i + 4 > tracks.length) ? tracks.length : i + 4),
          );
        }

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          // Important for consistent spacing and preventing clipping of items
          clipBehavior: Clip.none,
          itemCount: groupedTracks.length,
          separatorBuilder: (context, index) => const SizedBox(width: 16), // Space between columns
          itemBuilder: (context, colIndex) {
            final columnTracks = groupedTracks[colIndex];
            return SizedBox(
              width: 250, // Fixed width for each column to make it scannable
              child: Column(
                children: List.generate(columnTracks.length, (rowIndex) {
                  final track = columnTracks[rowIndex];
                  final trackNumber = (colIndex * 4) + rowIndex + 1; // Calculate global track number
                  return Padding(
                    padding: rowIndex < columnTracks.length - 1 ? const EdgeInsets.only(bottom: 8.0) : EdgeInsets.zero,
                    child: _buildTrackListItem(track, trackNumber), // Refined individual track item
                  );
                }),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds an individual track list item with a refined UI.
  Widget _buildTrackListItem(Track track, int trackNumber) {
    return GestureDetector(
      onTap: () async {
        // HapticFeedback.lightImpact(); // Uncomment for haptic feedback
        print('Tapped on track: ${track.title}');
        // Play song logic
        if (track.streamingUri.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This track does not have a streaming URL.')),
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
          duration: track.durationMs,
          albumArt: albumArtBytes,
        );

        try {
          print("Playing URI: ${songToPlay.uri}");
          await PlaybackService().playSong(songToPlay);
        } catch (e) {
          debugPrint('Failed to play song: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error playing song.')),
          );
        }
      },
      child: Container(
        height: 60, // Consistent height for each track item
        decoration: BoxDecoration(
          color: widget.cardColor.withOpacity(0.7), // Slightly transparent for depth
          borderRadius: BorderRadius.circular(10.0), // Rounded corners
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
            // Track Number (prominent, left-aligned)
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(
                trackNumber.toString(),
                style: TextStyle(
                  color: widget.accentColor, // Use accent color for prominence
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Album Art (small, clean square)
            ClipRRect(
              borderRadius: BorderRadius.circular(6), // Slightly less rounded for a tighter look
              child: CachedNetworkImage(
                imageUrl: track.image,
                height: 44, // Small square image
                width: 44,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[800],
                  child: Center(
                    child: Icon(Icons.music_note, size: 24, color: widget.accentColor.withOpacity(0.5)),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child: Icon(Icons.broken_image, size: 24, color: Colors.grey[600]),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Track Title and Artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    track.title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    track.title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Optional: Play Icon or More Options
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(
                Icons.play_circle_fill_rounded, // Play icon at the end
                color: widget.accentColor.withOpacity(0.8),
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a shimmer loading effect for the grid items.
  Widget _buildLoadingShimmer() {
    final double itemHeight = 60;
    final double itemWidth = 250; // Match column width

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      itemCount: 2, // Show a couple of shimmer columns
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (context, colIndex) {
        return Shimmer.fromColors(
          baseColor: widget.cardColor.withOpacity(0.7),
          highlightColor: widget.cardColor.withOpacity(0.2),
          child: SizedBox(
            width: itemWidth,
            child: Column(
              children: List.generate(4, (rowIndex) { // 4 items per shimmer column
                return Padding(
                  padding: rowIndex < 3 ? const EdgeInsets.only(bottom: 8.0) : EdgeInsets.zero,
                  child: Container(
                    height: itemHeight,
                    decoration: BoxDecoration(
                      color: Colors.white, // Shimmer effect over white background
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }


  /// Builds an informative error state message.
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber, color: widget.accentColor, size: 48),
            const SizedBox(height: 12),
            Text(
              'Failed to load top tracks.',
              style: const TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Please check your connection and try again.',
              style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            // Optional: Retry button
            // const SizedBox(height: 16),
            // ElevatedButton.icon(
            //   onPressed: () {
            //     setState(() {
            //       _topTracksFuture = PlaylistService.fetchTracks('New Tamil Songs');
            //     });
            //   },
            //   icon: Icon(Icons.refresh, color: Colors.white),
            //   label: Text('Try Again', style: TextStyle(color: widget.accentColor)),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: widget.accentColor,
            //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  /// Builds a user-friendly message for when no content is available.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_music, color: textColor.withOpacity(0.6), size: 48),
            const SizedBox(height: 12),
            Text(
              'No top tracks found at the moment.',
              style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Discover new music in other sections!',
              style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
// Assuming textColor is defined elsewhere, e.g.:

// Assuming textColor is defined elsewhere, e.g.:
const Color textColor = Colors.white;

class AnimatedAppBarContent extends StatefulWidget {
  final Function(int)? onItemTapped;

  const AnimatedAppBarContent({super.key, this.onItemTapped});

  @override
  _AnimatedAppBarContentState createState() => _AnimatedAppBarContentState();
}

class _AnimatedAppBarContentState extends State<AnimatedAppBarContent> {
  String _currentText = 'Hi, J Sanjay Ram'; // Changed initial text to your example
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTextAnimation();
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  void _startTextAnimation() {
    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      setState(() {
        _currentText = _currentText == 'Hi, J Sanjay Ram' ? 'Musico' : 'Hi, J Sanjay Ram';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.black, // App bar background
      expandedHeight: 80.0, // Initial height of the app bar when expanded
      floating: true, // App bar floats over the content
      pinned: true, // App bar remains visible at the top when scrolled
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- Crucial for consistent alignment: Fixed-width SizedBox ---
            SizedBox(
              // Set a width that can fully contain "Hi, Deepasree" with its font size/weight
              width: 80.0, // Adjust this value if your text still clips or has too much empty space
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.4),
                        end: Offset.zero,
                      ).animate(animation),
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.95,
                          end: 1.0,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                  );
                },
                child: Text(
                  _currentText,
                  key: ValueKey<String>(_currentText),
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  // --- Ensures text always starts from the left within the SizedBox ---
                  textAlign: TextAlign.start,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.search, color: textColor, size: 20),
              onPressed: () {
                widget.onItemTapped?.call(1);
              },
              tooltip: 'Search',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
// Make sure your models/playlist.dart and services/playlist_service.dart are correctly defined.
// class Album {
//   final String id;
//   final String title;
//   final String image;
//
//   Album({required this.id, required this.title, required this.image});
//
//   factory Album.fromJson(Map<String, dynamic> json) {
//     return Album(
//       id: json['id'],
//       title: json['title'],
//       image: json['image'],
//     );
//   }
// }
//
// class Playlist {
//   final String id;
//   final String title;
//   final String image;
//
//   Playlist({required this.id, required this.title, required this.image});
//
//   factory Playlist.fromJson(Map<String, dynamic> json) {
//     return Playlist(
//       id: json['id'],
//       title: json['title'],
//       image: json['image'],
//     );
//   }
// }
//
// class PlaylistService {
//   static Future<List<Playlist>> fetchPlaylists(String country) async {
//     await Future.delayed(const Duration(seconds: 1));
//     return [
//       Playlist(id: 'p1', title: 'Romantic Hits', image: 'https://picsum.photos/id/10/200/200'),
//       Playlist(id: 'p2', title: 'Workout Jams', image: 'https://picsum.photos/id/100/200/200'),
//       Playlist(id: 'p3', title: 'Chill Vibes', image: 'https://picsum.photos/id/1000/200/200'),
//       Playlist(id: 'p4', title: 'Pop Anthems', image: 'https://picsum.photos/id/1001/200/200'),
//       Playlist(id: 'p5', title: 'Classical', image: 'https://picsum.photos/id/1002/200/200'),
//     ];
//   }
//
//   static Future<List<Album>> fetchFeaturedAlbums(String category) async {
//     await Future.delayed(const Duration(seconds: 1));
//     return [
//       Album(id: 'a1', title: 'Top Tamil Hits', image: 'https://picsum.photos/id/1003/200/200'),
//       Album(id: 'a2', title: 'New English Songs', image: 'https://picsum.photos/id/1004/200/200'),
//       Album(id: 'a3', title: 'Indie Discoveries', image: 'https://picsum.photos/id/1005/200/200'),
//       Album(id: 'a4', title: 'Rock Classics', image: 'https://picsum.photos/id/1006/200/200'),
//       Album(id: 'a5', title: 'Jazz Legends', image: 'https://picsum.photos/id/1008/200/200'),
//     ];
//   }
// }