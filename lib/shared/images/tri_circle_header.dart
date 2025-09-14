import 'package:flutter/material.dart';

import '../../theme/app_color.dart';

/// Reusable tri-circle header that scales proportionally to the screen.
/// All size-related params are expressed as factors of screen width for consistency.
class TriCircleHeader extends StatelessWidget {
  // Width of the whole widget as a fraction of the available width.
  final double widthFactor;

  // Circle diameter factors relative to screen width.
  final double mainFactor;
  final double sideFactor;

  // Horizontal overlap between circles as a fraction of screen width.
  final double overlapFactor;

  // Visual customization.
  final ImageProvider centerImage;
  final ImageProvider leftImage;
  final ImageProvider rightImage;
  final Color ringColor;
  final double ringWidthFactor;
  final bool addCenterShadow;

  const TriCircleHeader({
    super.key,
    required this.centerImage,
    required this.leftImage,
    required this.rightImage,
    this.widthFactor = 1.0,
    this.mainFactor = 0.30,
    this.sideFactor = 0.24,
    this.overlapFactor = 0.10,
    this.ringColor = Colors.white,
    this.ringWidthFactor = 0.015,
    this.addCenterShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    // Compute absolute sizes from factors (based on screen width).
    final totalWidth = w * widthFactor;
    final mainSize = w * mainFactor;
    final sideSize = w * sideFactor;
    final overlap = w * overlapFactor;
    final ringWidth = w * ringWidthFactor;

    // Height is driven by the largest circle.
    final height = mainSize;

    // Optional shadow for the center circle to pop it above others.
    final centerShadow =
        addCenterShadow
            ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: w * 0.03,
                offset: Offset(0, w * 0.01),
              ),
            ]
            : null;

    return SizedBox(
      width: totalWidth,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left circle (positioned to the left of the center by half of main + half overlap)
          Positioned(
            right: mainSize / 2 + overlap / 2,
            child: CircleImage(
              size: sideSize,
              image: leftImage,
              ringColor: ringColor,
              ringWidth: ringWidth,
            ),
          ),

          // Right circle
          Positioned(
            left: mainSize / 2 + overlap / 2,
            child: CircleImage(
              size: sideSize,
              image: rightImage,
              ringColor: ringColor,
              ringWidth: ringWidth,
            ),
          ),

          // Center circle
          CircleImage(
            size: mainSize,
            image: centerImage,
            ringColor: ringColor,
            ringWidth: ringWidth,
            shadow: centerShadow,
          ),
        ],
      ),
    );
  }
}

/// Simple circular image with optional ring and shadow.
class CircleImage extends StatelessWidget {
  final double size;
  final ImageProvider image;
  final Color ringColor;
  final double ringWidth;
  final List<BoxShadow>? shadow;

  const CircleImage({
    super.key,
    required this.size,
    required this.image,
    this.ringColor = AppColors.white,
    this.ringWidth = 3,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: shadow,
        border: Border.all(color: ringColor, width: ringWidth),
        image: DecorationImage(
          image: image,
          fit:
              BoxFit
                  .cover, // cover keeps the image fully cropped within the circle
        ),
      ),
    );
  }
}
