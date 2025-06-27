// services/playlist_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/playlist.dart';

class PlaylistService {
  static Future<List<Playlist>> fetchPlaylists(String query) async {
  try {
    final url = Uri.parse('https://saavn.dev/api/search/playlists?query=$query');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Add more robust checks for the response structure
      if (data['data'] != null && 
          data['data']['results'] != null && 
          data['data']['results'] is List) {
        
        final playlists = data['data']['results'] as List;
        return playlists.map((e) {
          try {
            return Playlist.fromJson(e);
          } catch (e) {
            // Return a default playlist if parsing fails
            return Playlist(
              id: 'error', 
              title: 'Invalid Playlist', 
              image: ''
            );
          }
        }).toList();
      }
      throw Exception('Invalid API response format');
    }
    throw Exception('API request failed with status ${response.statusCode}');
  } catch (e) {
    throw Exception('Network error: $e');
  }
}
static Future<List<Album>> fetchFeaturedAlbums(String query) async {
    try {
      final url = Uri.parse('https://saavn.dev/api/search/playlists?query=$query');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['data'] != null && 
            data['data']['results'] != null && 
            data['data']['results'] is List) {

          final albums = data['data']['results'] as List;
          return albums.map((e) {
            try {
              return Album.fromJson(e);
            } catch (_) {
              return Album(
                id: 'error',
                title: 'Invalid Album',
                image: '',
              );
            }
          }).toList();
        }
        throw Exception('Invalid API response format');
      }
      throw Exception('API request failed with status ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
static Future<List<Track>> fetchTracks(String query,{int limit = 32}) async {
    try {
      final url = Uri.parse('https://saavn.dev/api/search/songs?query=$query&limit=$limit');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['data'] != null &&
            data['data']['results'] != null &&
            data['data']['results'] is List) {
          final tracksData = data['data']['results'] as List;
          return tracksData.map((e) {
            try {
              return Track.fromJson(e);
            } catch (e) {
              // Log the error for debugging, but return a default track to prevent app crash
              print('Error parsing track: $e, Data: $e'); // Added 'e' to log data that caused the error
              return Track(
                id: 'error_${DateTime.now().millisecondsSinceEpoch}', // Unique ID for error tracks
                title: 'Invalid Track',
                image: '',
                streamingUri: '', // Default for streamingUri
                artistName: 'Unknown Artist',
                durationMs: 0 // Default for artistName
              );
            }
          }).toList();
        }
        throw Exception('Invalid API response format: Missing data or results list.');
      }
      throw Exception('API request failed with status ${response.statusCode}.');
    } catch (e) {
      // Catch specific network errors or general exceptions
      throw Exception('Failed to fetch tracks: $e');
    }
  }

static Future<List<Artist>> fetchArtists(String query, {int limit = 30}) async {
    try {
      final url = Uri.parse('https://saavn.dev/api/search/artists?query=$query&limit=$limit');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['data'] != null &&
            data['data']['results'] != null &&
            data['data']['results'] is List) {
          final artistsData = data['data']['results'] as List;
          return artistsData.map((e) {
            try {
              return Artist.fromJson(e);
            } catch (e) {
              print('Error parsing artist: $e, Data: $e');
              return Artist(
                id: 'error_${DateTime.now().millisecondsSinceEpoch}',
                name: 'Unknown Artist',
                image: '',
              );
            }
          }).toList();
        }
        throw Exception('Invalid API response format: Missing data or results list for artists.');
      }
      throw Exception('Artist API request failed with status ${response.statusCode}.');
    } catch (e) {
      throw Exception('Failed to fetch artists: $e');
    }
  }


static Future<List<Track>> fetchTracksForPlaylist(String playlistId) async {
  try {
    final url = Uri.parse('https://saavn.dev/api/playlists?id=$playlistId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['success'] == true &&
          data['data'] != null &&
          data['data']['songs'] != null &&
          data['data']['songs'] is List) {
        final tracksData = data['data']['songs'] as List;
        return tracksData.map((e) {
          try {
            return Track.fromJson(e);
          } catch (e) {
            print('Error parsing track: $e');
            return Track(
              id: 'error_${DateTime.now().millisecondsSinceEpoch}',
              title: 'Invalid Track',
              image: '',
              streamingUri: '',
              artistName: 'Unknown Artist',
              durationMs: 0,
            );
          }
        }).toList();
      }

      throw Exception('Invalid API response format: Missing data or songs list.');
    }

    throw Exception('API request failed with status ${response.statusCode}.');
  } catch (e) {
    throw Exception('Failed to fetch tracks: $e');
  }
}

static Future<List<Track>> fetchTracksForAlbum(String albumId) async {
  try {
    final url = Uri.parse('https://saavn.dev/api/albums?id=$albumId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['success'] == true &&
          data['data'] != null &&
          data['data']['songs'] != null &&
          data['data']['songs'] is List) {
        final tracksData = data['data']['songs'] as List;
        return tracksData.map((e) {
          try {
            return Track.fromJson(e);
          } catch (e) {
            print('Error parsing album track: $e');
            return Track(
              id: 'error_${DateTime.now().millisecondsSinceEpoch}',
              title: 'Invalid Track',
              image: '',
              streamingUri: '',
              artistName: 'Unknown Artist',
              durationMs: 0,
            );
          }
        }).toList();
      }

      throw Exception('Invalid API response format: Missing data or songs list.');
    }

    throw Exception('Album tracks API request failed with status ${response.statusCode}.');
  } catch (e) {
    throw Exception('Failed to fetch album tracks: $e');
  }
}


 static Future<List<Album>> fetchAlbums(String query, {int limit = 30}) async {
    try {
      final url = Uri.parse('https://saavn.dev/api/search/albums?query=$query&limit=$limit');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['data'] != null &&
            data['data']['results'] != null &&
            data['data']['results'] is List) {
          final albumsData = data['data']['results'] as List;
          return albumsData.map((e) {
            try {
              return Album.fromJson(e);
            } catch (e) {
              print('Error parsing album: $e, Data: $e');
              return Album(
                id: 'error_${DateTime.now().millisecondsSinceEpoch}',
                title: 'Invalid Album',
                image: '',
              );
            }
          }).toList();
        }
        throw Exception('Invalid API response format: Missing data or results list for albums.');
      }
      throw Exception('Album API request failed with status ${response.statusCode}.');
    } catch (e) {
      throw Exception('Failed to fetch albums: $e');
    }
  }
  
}

class Artist {
  final String id;
  final String name; // Artists typically have a 'name'
  final String image; // URL to the artist's image/thumbnail

  Artist({
    required this.id,
    required this.name,
    required this.image,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    // Extract the highest quality image URL for the artist
    String imageUrl = '';
    if (json['image'] != null && json['image'] is List && json['image'].isNotEmpty) {
      // Assuming the last image in the list is the highest quality
      imageUrl = json['image'].last['url'] ?? '';
    }

    return Artist(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Artist',
      image: imageUrl,
    );
  }

  @override
  String toString() {
    return 'Artist(id: $id, name: $name, image: $image)';
  }
}