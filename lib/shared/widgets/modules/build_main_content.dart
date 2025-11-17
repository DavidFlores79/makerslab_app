// ABOUTME: Main content builder for module details pages with platform selection
// ABOUTME: Uses tabs (segmented button) for ESP32 vs Arduino UNO platform selection with platform-specific content

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/home/domain/entities/module_detail.dart';
import '../../../features/home/domain/entities/ino_file.dart';
import '../../../features/home/domain/entities/platform_config.dart';
import '../../../core/domain/usecases/share_file_usecase.dart';
import '../../../core/ui/snackbar_service.dart';
import '../../../di/service_locator.dart';
import '../../../theme/app_color.dart';
import '../index.dart';

class BuildMainContent extends StatefulWidget {
  final ModuleDetail moduleDetail;

  const BuildMainContent({super.key, required this.moduleDetail});

  @override
  State<BuildMainContent> createState() => _BuildMainContentState();
}

class _BuildMainContentState extends State<BuildMainContent> {
  InoPlatform _selectedPlatform = InoPlatform.esp32; // Initialize with default
  static const String _kPlatformSelectionKey = 'LAST_SELECTED_PLATFORM';

  @override
  void initState() {
    super.initState();
    _loadLastSelectedPlatform();
  }

  Future<void> _loadLastSelectedPlatform() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPlatform = prefs.getString(_kPlatformSelectionKey);

    if (lastPlatform != null) {
      try {
        final platform = InoPlatform.fromString(lastPlatform);
        if (mounted) {
          setState(() {
            _selectedPlatform = platform;
          });
        }
      } catch (e) {
        // Keep default ESP32 if parsing fails
      }
    }
  }

  Future<void> _saveSelectedPlatform(InoPlatform platform) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPlatformSelectionKey, platform.displayName);
  }

  // Get the platform-specific configuration for the selected platform
  PlatformConfig _getSelectedPlatformConfig() {
    try {
      return widget.moduleDetail.platformConfigs.firstWhere(
        (config) => config.platform == _selectedPlatform,
      );
    } catch (e) {
      // Fallback to first platform if selected platform not found
      return widget.moduleDetail.platformConfigs.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get platform-specific data
    final platformConfig = _getSelectedPlatformConfig();

    // DEBUG: Print video URL to console
    print('DEBUG: Module ID: ${widget.moduleDetail.id}');
    print('DEBUG: Selected Platform: ${_selectedPlatform.displayName}');
    print('DEBUG: Video URL: ${platformConfig.videoUrl}');
    print('DEBUG: Has videoUrl: ${platformConfig.videoUrl != null}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Platform Selector (only show if multiple platforms available)
        if (widget.moduleDetail.platformConfigs.length > 1)
          _buildPlatformSelector(),

        const SizedBox(height: 16),

        // Action Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              Flexible(
                child: MainAppButton(
                  label: 'Interfaz',
                  onPressed: () => context.push(
                    '${widget.moduleDetail.route}${widget.moduleDetail.interfaceRoute}',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: MainAppButton(
                  variant: ButtonVariant.outlined,
                  label: 'Descargar INO',
                  onPressed: () => _onDownloadAndShare(context, platformConfig),
                ),
              ),
            ],
          ),
        ),

        // Instructions Section (platform-specific)
        InstructionsSection(instructions: platformConfig.instructions),
        const SizedBox(height: 30),

        // Video Player (platform-specific)
        if (platformConfig.videoUrl != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildVideoPlayer(platformConfig.videoUrl!),
            ),
          ),

        const SizedBox(height: 30),

        // Materials Section (platform-specific)
        BillOfMaterialsSection(materials: platformConfig.materials),
        const SizedBox(height: 200),
      ],
    );
  }

  /// Video Player Builder - Handles YouTube, Vimeo, and other platforms
  Widget _buildVideoPlayer(String videoUrl) {
    // Extract video ID from YouTube URL
    if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')) {
      final videoId = _extractYouTubeVideoId(videoUrl);
      if (videoId != null) {
        return YouTubePlayer(videoId: videoId);
      }
    }

    // TODO: Add support for other video platforms (Vimeo, custom players)
    // For now, fallback to showing a message if URL format is not recognized
    return Container(
      color: AppColors.gray100,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library, size: 48, color: AppColors.gray400),
            SizedBox(height: 8),
            Text(
              'Video no disponible',
              style: TextStyle(color: AppColors.gray600),
            ),
          ],
        ),
      ),
    );
  }

  /// Extract YouTube video ID from various URL formats
  String? _extractYouTubeVideoId(String url) {
    // Handle youtube.com/watch?v=VIDEO_ID
    final regExp1 = RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]+)');
    final match1 = regExp1.firstMatch(url);
    if (match1 != null) {
      return match1.group(1);
    }

    // Handle youtu.be/VIDEO_ID
    final regExp2 = RegExp(r'youtu\.be/([a-zA-Z0-9_-]+)');
    final match2 = regExp2.firstMatch(url);
    if (match2 != null) {
      return match2.group(1);
    }

    // Handle youtube.com/embed/VIDEO_ID
    final regExp3 = RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]+)');
    final match3 = regExp3.firstMatch(url);
    if (match3 != null) {
      return match3.group(1);
    }

    // If none of the patterns match, return null
    return null;
  }

  /// Platform Selector Widget (Tabs/Segmented Button)
  Widget _buildPlatformSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          const Text(
            'Plataforma:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 8),

          // Segmented Button (Tabs)
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<InoPlatform>(
              segments: [
                ButtonSegment<InoPlatform>(
                  value: InoPlatform.esp32,
                  label: const Text('ESP32'),
                  icon: const Icon(Icons.memory, size: 18),
                ),
                ButtonSegment<InoPlatform>(
                  value: InoPlatform.arduinoUno,
                  label: const Text('Arduino UNO'),
                  icon: const Icon(Icons.developer_board, size: 18),
                ),
              ],
              selected: {_selectedPlatform},
              onSelectionChanged: (Set<InoPlatform> selected) {
                setState(() {
                  _selectedPlatform = selected.first;
                });
                _saveSelectedPlatform(selected.first);

                // Analytics tracking (if implemented)
                // AnalyticsService.logEvent(
                //   name: 'platform_selected',
                //   parameters: {
                //     'module_id': widget.moduleDetail.id,
                //     'platform': selected.first.name,
                //   },
                // );
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
                  }
                  return Colors.transparent;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.white;
                  }
                  return AppColors.primary;
                }),
                side: WidgetStateProperty.all(
                  const BorderSide(color: AppColors.primary, width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDownloadAndShare(
    BuildContext context,
    PlatformConfig platformConfig,
  ) async {
    final shareFileUseCase = getIt<ShareFileUseCase>();
    final snackbarService = getIt<SnackbarService>();

    // Get the INO file from the platform config
    final inoFile = platformConfig.inoFile;

    // Share file with platform-specific text
    final result = await shareFileUseCase(
      assetPath: inoFile.filePath,
      fileName: inoFile.fileName,
      text:
          'Código ${_selectedPlatform.displayName} para ${widget.moduleDetail.title}',
      subject: 'Archivo INO - ${widget.moduleDetail.title}',
    );

    // Error handling
    result.fold(
      (failure) {
        String errorMessage;
        if (failure.message.contains('no encontrado')) {
          errorMessage = 'Error al compartir archivo: Archivo no encontrado';
        } else if (failure.message.contains('guardar')) {
          errorMessage =
              'Error al compartir archivo: No se pudo guardar el archivo';
        } else if (failure.message.contains('plataforma')) {
          errorMessage = 'Error al compartir archivo: Error de la plataforma';
        } else {
          errorMessage = 'Error al compartir archivo: Error desconocido';
        }

        snackbarService.show(
          message: errorMessage,
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          style: SnackbarStyle.withClose,
        );
      },
      (_) {
        // Success - no confirmation needed
      },
    );
  }
}
