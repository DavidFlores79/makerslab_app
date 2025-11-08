import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class FullWidthVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool loop;

  const FullWidthVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = true,
    this.loop = true,
  });

  @override
  State<FullWidthVideoPlayer> createState() => _FullWidthVideoPlayerState();
}

class _FullWidthVideoPlayerState extends State<FullWidthVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
          ..setLooping(widget.loop)
          ..initialize().then((_) {
            setState(() => _isInitialized = true);
            if (widget.autoPlay) _controller.play();
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _enterFullScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenVideoPlayer(controller: _controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(_controller),
              _ControlsOverlay(
                controller: _controller,
                onFullScreenPressed: _enterFullScreen,
              ),
              VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.red,
                  bufferedColor: Colors.white54,
                  backgroundColor: Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  final VideoPlayerController controller;
  final VoidCallback onFullScreenPressed;

  const _ControlsOverlay({
    required this.controller,
    required this.onFullScreenPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          () =>
              controller.value.isPlaying
                  ? controller.pause()
                  : controller.play(),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Icon(
              controller.value.isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              color: Colors.white,
              size: 64,
            ),
          ),
          Positioned(
            right: 8,
            bottom: 32,
            child: IconButton(
              icon: const Icon(Icons.fullscreen, color: Colors.white, size: 28),
              onPressed: onFullScreenPressed,
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const FullScreenVideoPlayer({super.key, required this.controller});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  @override
  void initState() {
    super.initState();
    // Forzamos modo horizontal
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Regresamos a modo vertical
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AspectRatio(
          aspectRatio: widget.controller.value.aspectRatio,
          child: VideoPlayer(widget.controller),
        ),
      ),
    );
  }
}
