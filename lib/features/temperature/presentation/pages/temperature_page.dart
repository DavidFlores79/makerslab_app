import 'package:flutter/material.dart';
import '../../../../../shared/widgets/index.dart';

class TemperaturePage extends StatelessWidget {
  static const String routeName = '/temperature';
  const TemperaturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PxBackAppBar(),
      body: const Center(child: Text('Página de Temperatura')),
    );
  }
}
