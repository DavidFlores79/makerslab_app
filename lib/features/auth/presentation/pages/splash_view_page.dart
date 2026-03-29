// ABOUTME: This file contains the splash screen page with animated logo
// ABOUTME: It displays a video animation and handles the fade-in transition
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../theme/app_color.dart';

class SplashViewPage extends StatefulWidget {
  static const String routeName = "/splash_view";
  final VoidCallback? onAnimationCompleted;

  const SplashViewPage({super.key, this.onAnimationCompleted});

  @override
  State<SplashViewPage> createState() => _SplashViewPageState();
}

class _SplashViewPageState extends State<SplashViewPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset(
      'assets/videos/logo_animated.mp4',
    );

    await _videoController!.initialize();

    if (mounted) {
      setState(() {
        _isVideoInitialized = true;
      });

      _fadeController.forward();
      _videoController!.play();

      // Listen for video completion
      _videoController!.addListener(() {
        if (_videoController!.value.position >=
            _videoController!.value.duration) {
          Future.delayed(const Duration(milliseconds: 500), () {
            widget.onAnimationCompleted?.call();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child:
            _isVideoInitialized && _videoController != null
                ? FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: size.width * 0.4,
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                )
                : const SizedBox.shrink(),
      ),
    );
  }
}
