// ABOUTME: Sticky bottom action bar for module pages
// ABOUTME: Appears after scrolling, contains primary/secondary action buttons

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../../features/home/domain/entities/module_detail.dart';
import '../../../features/home/domain/entities/platform_config.dart';
import '../index.dart';

class StickyBottomActionBar extends StatelessWidget {
  final bool isVisible;
  final ModuleDetail moduleDetail;
  final PlatformConfig platformConfig;
  final VoidCallback onInterfacePressed;
  final VoidCallback onDownloadPressed;

  const StickyBottomActionBar({
    super.key,
    required this.isVisible,
    required this.moduleDetail,
    required this.platformConfig,
    required this.onInterfacePressed,
    required this.onDownloadPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Adjust button flex ratios for small screens
    final primaryFlex = screenWidth < 360 ? 5 : 6;
    final secondaryFlex = screenWidth < 360 ? 5 : 4;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      offset: isVisible ? Offset.zero : const Offset(0, 1),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth < 360 ? 12 : 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  // Primary Button - Interface
                  Expanded(
                    flex: primaryFlex,
                    child: MainAppButton(
                      label: 'Abrir Interfaz',
                      icon: Symbols.play_circle,
                      onPressed: onInterfacePressed,
                    ),
                  ),

                  SizedBox(width: screenWidth < 360 ? 8 : 12),

                  // Secondary Button - Download
                  Expanded(
                    flex: secondaryFlex,
                    child: MainAppButton(
                      variant: ButtonVariant.outlined,
                      label: 'Código Arduino',
                      icon: Symbols.download,
                      onPressed: onDownloadPressed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
