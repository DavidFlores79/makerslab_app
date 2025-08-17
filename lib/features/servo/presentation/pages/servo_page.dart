import 'package:flutter/material.dart';
import '../../../../../shared/widgets/index.dart';
import '../../../../core/entities/instruction.dart';
import '../../../../core/entities/material.dart';
import '../../../../core/entities/module.dart';
import '../../../../core/usecases/share_file_usecase.dart';
import '../../../../di/service_locator.dart';

class ServoPage extends StatelessWidget {
  static const String routeName = '/servo';
  ServoPage({super.key});

  final MainModule mainModule = MainModule(
    title: 'title',
    description: 'description',
    image: 'assets/images/static/servo/servo1.png',
    inoFile: 'assets/files/DHT11_Arduino_ESP32.ino',
    instructions: [
      InstructionItem(
        title:
            '1. Conectar el sensor DHT11 y el modulo Bluetooth HC-05 al Protoboard ',
        description:
            'Descripción de la instrucción 1 para la ruta interna lorem ipsum dolor sit amet, consectetur adipiscing elit.',
        imagePath: 'assets/images/static/servo/instructions/instruction1.png',
        actionType: IntructionItemType.modalBottomSheet,
      ),
      InstructionItem(
        title: 'Instrucción 2',
        description: 'Descripción de la instrucción 2',
        actionType: IntructionItemType.externalUrl,
        actionValue: 'https://www.enlacetecnologias.mx',
      ),
      InstructionItem(
        title: 'Instrucción 3',
        description: 'Descripción de la instrucción 3',
        actionType: IntructionItemType.none,
      ),
      InstructionItem(
        title: 'Instrucción 4',
        description:
            'Descripción de la instrucción 4 para la ruta interna lorem ipsum dolor sit amet, consectetur adipiscing elit.',
        actionType: IntructionItemType.modalBottomSheet,
      ),
    ],
    materials: [
      MaterialItem(
        title: 'Microcontrolador ESP32',
        description:
            'Placa de desarrollo ESP32 con WiFi y Bluetooth integrados alskjdl askdjl aksdjlaks jdlak sjdlka sjldkaj sldk jalskd jlaksjd laksdl jalsdkjlaksjdlakjsdlakj sdlkaj sdl kajlsd kjalskdj lakdsjlaksjd lakjsdlakjds',
        qty: '1',
        imagePath: 'assets/images/static/materials/esp32.png',
        actionType: MaterialItemType.modalBottomSheet,
      ),
      MaterialItem(
        title: 'Sensor DHT11',
        description: 'Sensor de temperatura y humedad digital',
        qty: '1',
        imagePath: 'assets/images/static/materials/dht-11.png',
        actionType: MaterialItemType.modalBottomSheet,
      ),
      MaterialItem(
        title: 'Resistencia 10k',
        description: 'Componente para pull-up del DHT11 sensor',
        qty: '1',
        imagePath: 'assets/images/static/materials/resistance10k.png',
        actionType: MaterialItemType.modalBottomSheet,
      ),
      MaterialItem(
        title: 'Cables de conexión',
        description: 'Dupont o jumper cables para conexiones',
        qty: '1',
        imagePath: 'assets/images/static/materials/dupont-cables.png',
        actionType: MaterialItemType.modalBottomSheet,
      ),
      MaterialItem(
        title: 'Protoboard',
        description: 'Placa de pruebas para circuitos',
        qty: '1',
        imagePath: 'assets/images/static/materials/breadboard.png',
        actionType: MaterialItemType.modalBottomSheet,
      ),
      MaterialItem(
        title: 'Fuente de alimentación',
        description: '5V DC (USB) o 3.3V DC (3.3V) conector Molex',
        qty: '1',
        imagePath: 'assets/images/static/materials/powersupply.png',
        actionType: MaterialItemType.modalBottomSheet,
      ),
      MaterialItem(
        title: 'Software de programación',
        description: 'Instalar Arduino IDE',
        qty: '1',
        imagePath: 'assets/images/static/materials/arduino-uno.png',
        actionType: MaterialItemType.externalUrl,
        actionValue: 'https://www.arduino.cc/es/software',
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          MainSliverBackAppBar(
            assetImagePath:
                mainModule.image ?? 'assets/images/static/placeholder.png',
            centerTitle: true,
            backLabel: 'Servos',
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),
              _BuildMainContent(mainModule: mainModule),
            ]),
          ),
        ],
      ),
    );
  }
}

class _BuildMainContent extends StatelessWidget {
  final MainModule mainModule;

  const _BuildMainContent({super.key, required this.mainModule});

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
            child: YouTubePlayer(videoId: 'K98h51XuqBE'),
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
