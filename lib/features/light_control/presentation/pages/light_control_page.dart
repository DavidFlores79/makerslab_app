import 'package:flutter/material.dart';
import '../../../../../shared/widgets/index.dart';

class LightControlPage extends StatelessWidget {
  static const String routeName = '/light_control';
  const LightControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PxBackAppBar(),
      body: const Center(child: Text('Página de LightControl')),
    );
  }
}
