import 'package:flutter/material.dart';
import '../../../../theme/app_color.dart';
import '../../../../utils/util_image.dart';

class SplashViewPage extends StatefulWidget {
  static const String routeName = "/splash_view";
  final VoidCallback? onAnimationCompleted;

  const SplashViewPage({super.key, this.onAnimationCompleted});

  @override
  State<SplashViewPage> createState() => _SplashViewPageState();
}

class _SplashViewPageState extends State<SplashViewPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationCompleted?.call();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Fondo de imagen
        Positioned.fill(
          child: Image.asset(UtilImage.SIGN_IN_BACKGROUND_2, fit: BoxFit.cover),
        ),

        // Overlay oscuro
        Positioned.fill(
          child: Container(color: AppColors.black3.withOpacity(0.7)),
        ),

        // Logo animado
        Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Image.asset(
              UtilImage.PAISAMEX_LOGO_WHITE,
              width: size.width * 0.6,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}
