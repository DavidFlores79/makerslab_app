import 'package:flutter/material.dart';
import '../../../../../shared/widgets/index.dart';

class GamepadPage extends StatelessWidget {
  static const String routeName = '/gamepad';
  const GamepadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PxBackAppBar(),
      body: const Center(child: Text('Página de Gamepad')),
    );
  }
}
