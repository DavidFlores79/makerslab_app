import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/entities/module.dart';
import '../../../core/domain/usecases/share_file_usecase.dart';
import '../../../core/ui/snackbar_service.dart';
import '../../../di/service_locator.dart';
import '../index.dart';

class BuildMainContent extends StatelessWidget {
  final MainModule mainModule;

  const BuildMainContent({super.key, required this.mainModule});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // mejor alineación
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              Flexible(
                child: MainAppButton(
                  label: 'Interfaz',
                  onPressed:
                      () => context.push(
                        '${mainModule.moduleRoute}${mainModule.interfaceRoute}',
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: MainAppButton(
                  variant: ButtonVariant.outlined,
                  label: 'Descargar INO',
                  onPressed: () => _onDownloadAndShare(context),
                ),
              ),
            ],
          ),
        ),
        InstructionsSection(instructions: mainModule.instructions ?? []),
        const SizedBox(height: 30),

        // 👇 Aquí el cambio importante
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: AspectRatio(
            aspectRatio: 16 / 9, // proporción estándar de video
            child: YouTubePlayer(videoId: mainModule.videoId ?? 'K98h51XuqBE'),
          ),
        ),

        const SizedBox(height: 30),
        BillOfMaterialsSection(materials: mainModule.materials ?? []),
        const SizedBox(height: 200),
      ],
    );
  }

  Future<void> _onDownloadAndShare(BuildContext context) async {
    final shareFileUseCase = getIt<ShareFileUseCase>();
    final snackbarService = getIt<SnackbarService>();

    // Share file with module-specific text and subject (Decision D2)
    final result = await shareFileUseCase(
      assetPath: mainModule.inoFile,
      fileName: mainModule.inoFile.split('/').last,
      text: 'Código Arduino para ${mainModule.title}',
      subject: 'Archivo INO - ${mainModule.title}',
    );

    // Handle Either result - only show error messages (Decision B1: silent on success/dismissal)
    result.fold(
      (failure) {
        // Map failure to user-friendly Spanish error message (Decision C2: specific errors)
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

        // Show error snackbar with red background
        snackbarService.show(
          message: errorMessage,
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          style: SnackbarStyle.withClose,
        );
      },
      (_) {
        // Success or user dismissal - show nothing (Decision B1)
        // User knows what they did, no need for confirmation
      },
    );
  }
}
