import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_gif/flutter_gif.dart';
import '../models/file_model.dart';

class PlayerScreen extends StatefulWidget {
  final FileModel file;

  const PlayerScreen({super.key, required this.file});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  FlutterGifController? _gifController;
  bool _isPlaying = false;
  bool _isRepeat = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    if (widget.file.type == 'video' || widget.file.type == 'm3u8') {
      _videoController = VideoPlayerController.network(widget.file.path)
        ..initialize().then((_) {
          setState(() {});
          _videoController!.setLooping(_isRepeat);
        });
    } else if (widget.file.type == 'audio') {
      _audioPlayer = AudioPlayer();
      _audioPlayer!.setSource(DeviceFileSource(widget.file.path));
      _audioPlayer!.setReleaseMode(_isRepeat ? ReleaseMode.loop : ReleaseMode.release);
    } else if (widget.file.type == 'gif') {
      _gifController = FlutterGifController(vsync: this);
      // Note: GIF loading would need actual implementation
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (widget.file.type == 'video' || widget.file.type == 'm3u8') {
        _isPlaying ? _videoController!.play() : _videoController!.pause();
      } else if (widget.file.type == 'audio') {
        _isPlaying ? _audioPlayer!.resume() : _audioPlayer!.pause();
      } else if (widget.file.type == 'gif') {
        _isPlaying ? _gifController!.repeat() : _gifController!.stop();
      }
    });
  }

  void _toggleRepeat() {
    setState(() {
      _isRepeat = !_isRepeat;
      if (widget.file.type == 'video' || widget.file.type == 'm3u8') {
        _videoController!.setLooping(_isRepeat);
      } else if (widget.file.type == 'audio') {
        _audioPlayer!.setReleaseMode(_isRepeat ? ReleaseMode.loop : ReleaseMode.release);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name),
        backgroundColor: const Color(0xFFFF0000),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Color(0xFFFF0000)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.file.type == 'video' || widget.file.type == 'm3u8')
                _videoController != null && _videoController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                  : const CircularProgressIndicator(color: Color(0xFFFF0000)),
              if (widget.file.type == 'audio')
                Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.music_note,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              if (widget.file.type == 'gif')
                Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey,
                  child: const Center(
                    child: Text(
                      'GIF Player',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  // Would implement actual GIF playback
                ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 48,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: Icon(
                      _isRepeat ? Icons.repeat : Icons.repeat_one,
                      color: _isRepeat ? const Color(0xFFFF0000) : Colors.white,
                      size: 48,
                    ),
                    onPressed: _toggleRepeat,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    _gifController?.dispose();
    super.dispose();
  }
}