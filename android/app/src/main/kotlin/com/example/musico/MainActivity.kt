package com.example.musico // <<< REPLACE with your actual package name

import com.ryanheise.audioservice.AudioServiceActivity // Import AudioServiceActivity
import io.flutter.embedding.android.FlutterActivity // Can be FlutterActivity, but AudioServiceActivity is better
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: AudioServiceActivity() { // <<< IMPORTANT: Extend AudioServiceActivity
    // You typically don't need to override configureFlutterEngine for audio_service
    // as AudioServiceActivity handles it.
    // If you had other plugins requiring this, you'd add them here.
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
    
}