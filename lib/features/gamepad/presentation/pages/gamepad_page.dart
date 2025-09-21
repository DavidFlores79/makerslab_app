import 'package:flutter/material.dart';
import '../../../../../shared/widgets/index.dart';
import '../../../../core/entities/instruction.dart';
import '../../../../core/entities/material.dart';
import '../../../../core/entities/module.dart';
import '../../../../shared/widgets/chat/px_chatbot_floating_button.dart';

class GamepadPage extends StatelessWidget {
  static const String routeName = '/gamepad';
  GamepadPage({super.key});

  final MainModule mainModule = MainModule(
    title: 'title',
    description: 'description',
    image: 'assets/images/static/gamepad/gamepad.png',
    videoId: 'kJpdoBLSmHs',
    inoFile: 'assets/files/Gamepad_Arduino_ESP32.ino',
    instructions: [
      InstructionItem(
        title:
            '1. Conectar el modulo Bluetooth HC-05 al Protoboard y al Arduino a través de los pines TX y RX.',
        description:
            'Descripción de la instrucción 1 para la ruta interna lorem ipsum dolor sit amet, consectetur adipiscing elit.',
        imagePath: 'assets/images/static/gamepad/instructions/instruction1.png',
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
            backLabel: 'GamePad',
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),
              BuildMainContent(mainModule: mainModule),
            ]),
          ),
        ],
      ),
      floatingActionButton: const PxChatBotFloatingButton(
        moduleKey: 'joystick_control',
      ),
    );
  }
}
