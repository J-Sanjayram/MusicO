import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player;

  MyAudioHandler({required AudioPlayer audioPlayer}) : _player = audioPlayer {
    // Pipe the just_audio player's playback events to audio_service
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Listen to changes in the player's current song (sequence state)
    // and update the mediaItem stream for audio_service.
    _player.sequenceStateStream.listen((sequenceState) {
      if (sequenceState.currentSource != null) {
        // The tag should already be a MediaItem set by PlaybackService
        mediaItem.add(sequenceState.currentSource!.tag as MediaItem?);
      }
    });

    // Listen to player's duration changes to update mediaItem duration
    _player.durationStream.listen((duration) {
      if (mediaItem.value != null && duration != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: duration));
      }
    });
  }

  // Transforms just_audio's ProcessingState to audio_service's AudioProcessingState
  AudioProcessingState _getAudioProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
      updatePosition: Duration.zero,
    ));
    mediaItem.add(null); // Clear media item when stopped
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  // setMediaItem is no longer an override. We update the stream instead.
  // The PlaybackService is responsible for calling _player.setFilePath
  // and setting the tag, which then flows through the sequenceStateStream listener.

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.play,
        MediaAction.pause,
        MediaAction.seek,
        MediaAction.stop,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _getAudioProcessingState(_player.processingState),
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }
}