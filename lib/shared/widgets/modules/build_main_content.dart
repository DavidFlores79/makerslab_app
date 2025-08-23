import 'package:flutter/material.dart';

import '../../../core/entities/module.dart';
import '../../../core/usecases/share_file_usecase.dart';
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
                child: MainAppButton(label: 'Interfaz', onPressed: () {}),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: MainAppButton(
                  variant: ButtonVariant.outlined,
                  label: 'Descargar INO',
                  onPressed: () => _onDownloadAndShare(),
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

  Future<void> _onDownloadAndShare() async {
    final shareFileUseCase = getIt<ShareFileUseCase>();

    await shareFileUseCase(
      assetPath: mainModule.inoFile,
      fileName: mainModule.inoFile.split('/').last,
      text: 'Aquí tienes tu archivo INO',
    );
  }
}
