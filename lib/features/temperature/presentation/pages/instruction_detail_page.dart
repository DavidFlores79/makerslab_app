import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/entities/instruction.dart';
import '../../../../shared/widgets/instructions/helpers/instruction_actions.dart';

class TemperatureInstructionDetailsPage extends StatelessWidget {
  static const String routeName = '/instruction_details';
  final List<InstructionItem> instructions;

  const TemperatureInstructionDetailsPage({
    super.key,
    required this.instructions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instrucciones'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _BuildMainContent(instructions: instructions),
    );
  }
}

class _BuildMainContent extends StatelessWidget {
  final List<InstructionItem> instructions;
  const _BuildMainContent({required this.instructions});

  IconData _getIconForType(IntructionItemType type) {
    switch (type) {
      case IntructionItemType.internalRoute:
        return Icons.arrow_forward_ios;
      case IntructionItemType.externalUrl:
        return Icons.link;
      case IntructionItemType.modalBottomSheet:
        return Icons.paste_rounded;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: instructions.length,
      itemBuilder: (context, index) {
        final instruction = instructions[index];

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => handleInstructionItemTap(context, instruction),
            child: IntrinsicHeight(
              // <- iguala la altura de los hijos
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    child: SizedBox(
                      width: 100,
                      height:
                          double
                              .infinity, // <- ahora sí está acotado por IntrinsicHeight
                      child: Image.asset(
                        instruction.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) =>
                                Container(color: Colors.grey.shade200),
                      ),
                    ),
                  ),

                  // Contenido
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            instruction.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            instruction.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          // pequeña fila con icono de tipo a la derecha si quieres
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                _getIconForType(instruction.actionType),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
