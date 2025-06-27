// models/playlist.dart
class Playlist {
  final String id;
  final String title;
  final String image;

  Playlist({required this.id, required this.title, required this.image});

  factory Playlist.fromJson(Map<String, dynamic> json) {
  return Playlist(
    id: json['id']?.toString() ?? '',
    title: json['name']?.toString() ?? 'Untitled Playlist', // Change 'title' to 'name'
    image: json['image'] != null && json['image'].length > 1
           ? json['image'][1]['url']  // Select the second image
           : (json['image']?.isNotEmpty ?? false) 
             ? json['image'][0]['url'] // Fallback to first image if only one exists
             : '', // Extract first image URL safely
  );
}

}


class Album {
  final String id;
  final String title;
  final String image;

  Album({
    required this.id,
    required this.title,
    required this.image,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id']?.toString() ?? '',
      title: json['name']?.toString() ?? 'Untitled Playlist', // Change 'title' to 'name'
      image: json['image'] != null && json['image'].length > 1
            ? json['image'][1]['url']  // Select the second image
            : (json['image']?.isNotEmpty ?? false) 
              ? json['image'][0]['url'] // Fallback to first image if only one exists
              : '', 
    );
  }
}

// models/track.dart
class Track {

  final int durationMs; // Duration in milliseconds

  final String id;
  final String title;
  final String image; // URL to the highest quality album art image
  final String streamingUri; // The highest quality URI for streaming the song
  final String? artistName; // To store the primary artist's name

  Track({
    required this.id,
    required this.title,
    required this.image,
    required this.streamingUri,
    this.artistName,
    required this.durationMs, // <--- ADD 'required' HERE

  });

  factory Track.fromJson(Map<String, dynamic> json) {
    final int durationInSeconds = json['duration'] as int? ?? 0;
    final int durationInMs = durationInSeconds * 1000;
    String rawTitle = json['name'] ?? 'Unknown Title';
    String cleanedTitle = _cleanTrackTitle(rawTitle); // Apply the cleaning here

    // Extract the highest quality image URL
    String imageUrl = '';
    if (json['image'] != null && json['image'] is List && json['image'].isNotEmpty) {
      // Assuming the last image in the list is the highest quality
      imageUrl = json['image'].last['url'] ?? '';
    }

    // Extract the highest quality streaming URI from 'downloadUrl'
    String streamUrl = '';
    if (json['downloadUrl'] != null &&
        json['downloadUrl'] is List &&
        json['downloadUrl'].isNotEmpty) {
      // Assuming the last downloadUrl in the list is the highest quality (320kbps)
      streamUrl = json['downloadUrl'].last['url'] ?? '';

      // Convert http to https if the URL starts with http://
      if (streamUrl.startsWith('http://')) {
        streamUrl = streamUrl.replaceFirst('http://', 'https://');
      }
    }


    // Extract the primary artist's name
    String? primaryArtistName;
    if (json['artists'] != null && json['artists']['primary'] != null && json['artists']['primary'] is List && json['artists']['primary'].isNotEmpty) {
      primaryArtistName = json['artists']['primary'][0]['name']; // Get the name of the first primary artist
    }


    return Track(
      id: json['id'],
      title: cleanedTitle,
      image: imageUrl,
      streamingUri: streamUrl,
      artistName: primaryArtistName,
      durationMs: durationInMs, // Assigned here

    );
  }
  @override
  String toString() {
    return 'Track(id: $id, title: $title, artist: $artistName, image: $image, streamingUri: $streamingUri)';
  }

  static String _cleanTrackTitle(String title) {
  // Replace &quot; (double quote HTML entity) with a plain double quote
  String cleaned = title.replaceAll('&quot;', '"');

  // Replace &apos; (apostrophe HTML entity) with a plain single quote, if present
  cleaned = cleaned.replaceAll('&apos;', "'");

  // Replace &amp; (ampersand HTML entity) with a plain ampersand, if present
  cleaned = cleaned.replaceAll('&amp;', '&');

  // Handle the "From "..." syntax specifically
  // This regex finds "From " followed by anything non-quote, then another quote,
  // and captures the content inside the quotes.
  // It replaces the whole match with "From " and the captured content.
  // This handles both single and double quotes around the "From" part.
  cleaned = cleaned.replaceAllMapped(RegExp(r'From ["\"](.+?)["\"]'), (match) {
    return 'From ${match.group(1)}';
  }
  );

  // Remove any remaining single or double quotes
  cleaned = cleaned.replaceAll('"', '');
  cleaned = cleaned.replaceAll("'", '');

  // Replace multiple spaces with a single space
  cleaned = cleaned.replaceAll(RegExp(r' {2,}'), ' ');

  //print("THE FILTER OF THE SEARCH" + cleaned);

  return cleaned.trim(); // Trim leading/trailing spaces
}
}