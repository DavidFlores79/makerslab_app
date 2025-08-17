import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class FullscreenYoutubePlayer extends StatefulWidget {
  final String videoId;
  final Duration initialPosition;
  final bool isPlaying;

  const FullscreenYoutubePlayer({
    super.key,
    required this.videoId,
    required this.initialPosition,
    required this.isPlaying,
  });

  @override
  State<FullscreenYoutubePlayer> createState() =>
      _FullscreenYoutubePlayerState();
}

class _FullscreenYoutubePlayerState extends State<FullscreenYoutubePlayer> {
  @override
  void initState() {
    super.initState();
    // Cambia a landscape y oculta barras
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    // Regresa a portrait y muestra barras
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: YoutubePlayer(
              controller: YoutubePlayerController(
                initialVideoId: widget.videoId,
                flags: YoutubePlayerFlags(
                  autoPlay: widget.isPlaying,
                  mute: false,
                ),
              ),
              showVideoProgressIndicator: true,
            ),
          ),
          Positioned(
            top: 24,
            left: 24,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
