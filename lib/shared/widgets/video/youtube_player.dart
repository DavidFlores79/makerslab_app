import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'fullscreen_youtube_player.dart';

class YouTubePlayer extends StatefulWidget {
  final String videoId;

  const YouTubePlayer({super.key, required this.videoId});

  @override
  State<YouTubePlayer> createState() => _YouTubePlayerState();
}

class _YouTubePlayerState extends State<YouTubePlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        useHybridComposition: true,
      ),
    );

    _controller.addListener(_listener);
  }

  void _listener() {
    if (_controller.value.isFullScreen) {
      // Cancelamos el fullscreen interno
      _controller.toggleFullScreenMode();

      // Guardamos el estado actual
      final position = _controller.value.position;
      final isPlaying = _controller.value.isPlaying;

      // Abrimos nuestra propia pantalla
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => FullscreenYoutubePlayer(
                videoId: widget.videoId,
                initialPosition: position,
                isPlaying: isPlaying,
              ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
      ),
    );
  }
}
