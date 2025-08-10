import 'package:flutter/material.dart';
import 'package:makerslab_app/shared/widgets/index.dart';

import '../../../../core/entities/instruction.dart';

class TemperatureInstructionDetailsPage extends StatelessWidget {
  static const String routeName = '/instruction_details';
  final List<Instruction> intructions;
  const TemperatureInstructionDetailsPage({
    super.key,
    required this.intructions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SecondarySliverAppBar(
            expandedHeight: 130,
            title: 'Instruction Details (${intructions.length})',
            subtitle: 'Paso a paso para conectar el sensor',
            // backgroundImage: 'assets/images/instructions_bg.jpg',
            onBack: () => Navigator.of(context).pop(),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Tu contenido
                const Text(
                  'Instruction Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // ... resto
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildMainContent extends StatelessWidget {
  const _BuildMainContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Instruction Details',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
