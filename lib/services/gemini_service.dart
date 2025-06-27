// lib/services/gemini_service.dart
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert'; // For JSON encoding/decoding

class GeminiService {
  final String _apiKey;
  late final GenerativeModel _model;

  GeminiService(this._apiKey) {
    _model = GenerativeModel(
      model: 'gemini-flash', // Or 'gemini-1.5-flash' for faster responses
      apiKey: _apiKey,
    );
  }

  Future<Map<String, dynamic>> getMusicHomepage(
    String nowPlayingTitle,
    String nowPlayingArtist,
    String username,
  ) async {
    final prompt = """
You are a music recommendation and discovery assistant. Your task is to act like Spotify’s homepage engine. Based on a currently playing song (title and artist), you must generate a personalized music discovery homepage with sections and playlists.
🎧 Input Data Format (Example)
json
{
"now_listening": {
"title": "$nowPlayingTitle",
"artist": "$nowPlayingArtist"
},
"username": "$username"}
🧠 What You Must Do
Using the now listening song metadata:

Analyze the current track’s genre, mood, tempo, era, and general vibe.
Build a mock music homepage with dynamic sections, including:
🎵 For You, $username
🔥 Trending Now
🎧 Because You Listened to '$nowPlayingTitle'
💃 Dance Party
💤 Chill Vibes
📻 Retro Flashback
In each section, include:
Playlist titles
Short descriptions
5 to 10 curated songs (song title and artist)
All playlists must relate to the now playing song either by genre, mood, influence, or listener behavior.
Output should dynamically adapt if the now listening song changes.
📄 Output Format Example
json
{
"homepage": {
"For You, Alex": {
"description": "Handpicked tracks based on your recent plays.",
"playlists": [
{
"title": "Synthwave Sunset",
"description": "Retro vibes with modern production.",
"songs": [
{"title": "Midnight City", "artist": "M83"},
{"title": "Electric Feel", "artist": "MGMT"},
{"title": "Out of My League", "artist": "Fitz and The Tantrums"},
{"title": "Physical", "artist": "Dua Lipa"},
{"title": "Real Hero", "artist": "College & Electric Youth"}
]
}
]
},
"Because You Listened to 'Blinding Lights'": {
"description": "More synth-pop and retro-inspired tracks.",
"songs": [
{"title": "Take On Me", "artist": "a-ha"},
{"title": "Style", "artist": "Taylor Swift"},
{"title": "Get Lucky", "artist": "Daft Punk"},
{"title": "Cool", "artist": "Dua Lipa"},
{"title": "Stolen Dance", "artist": "Milky Chance"}
]
},
"Chill Vibes": {
"description": "Laid-back electronic and pop sounds to relax.",
"songs": [
{"title": "Sunflower", "artist": "Post Malone"},
{"title": "Electric", "artist": "Alina Baraz"},
{"title": "The Less I Know The Better", "artist": "Tame Impala"},
{"title": "Ocean Eyes", "artist": "Billie Eilish"}
]
}
}
Please ensure the output is valid JSON.
""";

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null) {
        // Gemini might sometimes include markdown in the JSON response,
        // so we need to clean it up.
        String jsonString = response.text!
            .replaceAll('```json\n', '')
            .replaceAll('\n```', '');
        return json.decode(jsonString) as Map<String, dynamic>;
      } else {
        throw Exception("Gemini response was empty.");
      }
    } catch (e) {
      print("Error calling Gemini API: $e");
      rethrow;
    }
  }

  // You can add another method for music creation based on prompts
  Future<String> createMusicPrompt(String userPrompt) async {
    final prompt = """
Based on the following user prompt, suggest a song title and artist that fits the description, and briefly explain why.
User Prompt: "$userPrompt"
Output Format: "Title: [Song Title]\nArtist: [Artist Name]\nExplanation: [Reason]"
""";
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "Could not create music. Please try again.";
    } catch (e) {
      print("Error creating music: $e");
      rethrow;
    }
  }
}
