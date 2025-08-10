import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YouTubePlayer extends StatefulWidget {
  final String videoId;

  const YouTubePlayer({super.key, required this.videoId});

  @override
  State<YouTubePlayer> createState() => _YouTubePlayerState();
}

class _YouTubePlayerState extends State<YouTubePlayer> {
  late YoutubePlayerController _controller;
  bool _isPlayerVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        // forceHD: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9, // Mantener proporción estándar de video
      child:
          _isPlayerVisible
              ? YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                onReady: () => debugPrint("YouTube Player listo"),
              )
              : GestureDetector(
                onTap: () {
                  setState(() {
                    _isPlayerVisible = true;
                  });
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      YoutubePlayer.getThumbnail(videoId: widget.videoId),
                      fit: BoxFit.cover,
                    ),
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
