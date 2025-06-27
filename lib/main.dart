import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:audio_session/audio_session.dart';

import 'screens/NowPlayingBar .dart'; // Corrected path/spacing
import 'services/audio_service.dart'; // Your custom AudioService for scanning
import 'services/songs_provider.dart';
import 'screens/landing_page.dart';
import 'screens/library_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/search_screen.dart'; // Corrected import
import 'theme/app_theme.dart';
import 'services/PlaybackService .dart'; // Ensure PlaybackService is imported

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure audio session for background playback
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Request permissions before the app starts
  try {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    final isAndroid13OrAbove = deviceInfo.version.sdkInt >= 33;
    final permission =
        isAndroid13OrAbove ? Permission.audio : Permission.storage;

    if (!await permission.request().isGranted) {
      // If permission is denied, you might want to show a dialog
      // and then exit, or guide the user to settings.
      // For simplicity, we'll just print an error and proceed,
      // but in a real app, you'd handle this more robustly.
      print('Permission denied. App might not function correctly.');
      // Optionally, show a dialog and exit:
      // SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    }
  } catch (e) {
    print("Error requesting permissions: $e");
    // Handle error, e.g., show a dialog to the user
  }
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.black.withOpacity(0.2), // Your desired color
    systemNavigationBarColor: Colors.black
    // You can also set statusBarIconBrightness here to control icon color
    // statusBarIconBrightness: Brightness.light, // For light icons on dark background
    // statusBarIconBrightness: Brightness.dark,  // For dark icons on light background
  ));

  // Initialize the PlaybackService early in the app lifecycle
  // The PlaybackService constructor itself handles its own _init()
  // and will initialize audio_service and the just_audio player.
  PlaybackService();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Musico',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const MainNavigationScreen(), // Directly go to MainNavigationScreen
      routes: {
        '/player': (context) => const NowPlayingBar(), // Example route for player
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final SongsProvider _songsProvider = SongsProvider();
  late final List<Widget> _screens;

  // Define your royal colors here, consistent with LandingPage
  static const Color primaryColor = Color.fromARGB(255, 0, 0, 0); // Dark blue/purple
  static const Color accentColor = Color.fromARGB(255, 248, 215, 0); // Deep rose/red
  static const Color textColor = Color.fromARGB(255, 125, 125, 125); // Light grey for text

  @override
  void initState() {
    super.initState();
    _screens = [
      LandingPage(onItemTapped: _onItemTapped),
      SearchScreen(), // Pass songsProvider to SearchScreen
      LibraryScreen(songsProvider: _songsProvider),
      const SubscriptionScreen(),
    ];
    _loadSongs(); // Start loading songs when the main screen initializes
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await AudioService.getSongs(forceRefresh: false);
      _songsProvider.updateSongs(songs);
    } catch (e) {
      print("Error loading songs: $e");
      // You could show a SnackBar or a small error message on the relevant screen
      // e.g., ScaffoldMessenger.of(context).showSnackBar(...)
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define your primary color (if not already in a theme)
   // const Color primaryColor = Color.fromRGBO(69, 83, 233, 1);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
          const NowPlayingBar(), // Always visible
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        // --- Styling for light yellow theme and icon alignment ---
        type: BottomNavigationBarType.fixed, // Ensures all items are visible and evenly spaced
        backgroundColor:Colors.transparent, // Very light yellow (Lemon Chiffon)
        selectedItemColor: const Color.fromARGB(255, 255, 238, 0), // Goldenrod for selected item
        unselectedItemColor: Colors.grey[600], // Darker grey for unselected, contrasting with light yellow
        selectedIconTheme: const IconThemeData(size: 20.0), // Larger icon for selected state
        unselectedIconTheme: const IconThemeData(size: 20.0), // Slightly smaller icon for unselected state
        showSelectedLabels: false, // Ensure labels are hidden
        showUnselectedLabels: false, // Ensure labels are hidden
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '', // Label must be empty for icons to appear "aligned"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: '',
          )
        ],
      ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => Navigator.pushNamed(context, '/player'),
      //   backgroundColor: const Color.fromRGBO(69, 83, 233, 1),
      //   elevation: 8,
      //   shape: const CircleBorder(),
      //   child: const Icon(Icons.play_arrow, color: primaryColor, size: 32),
      // ),
    );
  }

  // Helper method to build consistent navigation bar items
  Widget _buildNavItem(int index, IconData icon, String label) {
    return InkWell(
      onTap: () => _onItemTapped(index),
      highlightColor: Colors.transparent, // Remove default splash on tap
      splashColor: Colors.transparent, // Remove default splash on tap
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: _selectedIndex == index ? accentColor : textColor.withOpacity(0.7), // Highlight selected
            size: 30,
          ),
        ],
      ),
    );
  }
}