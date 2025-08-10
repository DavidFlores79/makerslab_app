import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:makerslab_app/core/entities/material.dart';
import 'package:makerslab_app/core/entities/module.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../shared/widgets/index.dart';
import '../../../../core/entities/instruction.dart';
import '../../../../theme/app_color.dart';

class TemperaturePage extends StatelessWidget {
  static const String routeName = '/temperature';
  TemperaturePage({super.key});

  final MainModule mainModule = MainModule(
    title: 'title',
    description: 'description',
    image: 'assets/images/static/esp32DHT11.png',
    instructions: [
      InstructionItem(
        title:
            '1. Conectar el sensor DHT11 y el modulo Bluetooth HC-05 al Protoboard ',
        description:
            'Descripción de la instrucción 1 para la ruta interna lorem ipsum dolor sit amet, consectetur adipiscing elit.',
        imagePath: 'assets/images/static/instruction1.png',
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
        actionType: MaterialItemType.modalBottomSheet,
      ),
      MaterialItem(
        title: 'Resistencia 10k',
        description: 'Componente para pull-up del DHT11 sensor',
        qty: '1',
        actionType: MaterialItemType.modalBottomSheet,
      ),
      MaterialItem(
        title: 'Cables de conexión',
        description: 'Dupont o jumper cables para conexiones',
        qty: '1',
        actionType: MaterialItemType.modalBottomSheet,
      ),
      MaterialItem(
        title: 'Protoboard',
        description: 'Placa de pruebas para circuitos',
        qty: '1',
        actionType: MaterialItemType.modalBottomSheet,
      ),
      MaterialItem(
        title: 'Fuente de alimentación',
        description: '5V DC (USB) o 3.3V DC (3.3V) conector Molex',
        qty: '1',
        actionType: MaterialItemType.modalBottomSheet,
      ),
      MaterialItem(
        title: 'Software de programación',
        description: 'Instalar Arduino IDE',
        qty: '1',
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
            backLabel: 'DHT11 Temperatura',
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
      children: [
        // Aquí iría el contenido real de la pantalla
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
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
        InstructionsSection(instructions: mainModule.instructions ?? []),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: YouTubePlayer(videoId: 'K98h51XuqBE'),
        ),
        const SizedBox(height: 30),
        BillOfMaterialsSection(materials: mainModule.materials ?? []),
        const SizedBox(height: 200), // Solo para probar el scroll
      ],
    );
  }
}
