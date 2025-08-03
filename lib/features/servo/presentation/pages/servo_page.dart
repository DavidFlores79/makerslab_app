import 'package:flutter/material.dart';
import '../../../../../shared/widgets/index.dart';

class ServoPage extends StatelessWidget {
  static const String routeName = '/servo';
  const ServoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PxBackAppBar(),
      body: const Center(child: Text('Página de Servos')),
    );
  }
}
