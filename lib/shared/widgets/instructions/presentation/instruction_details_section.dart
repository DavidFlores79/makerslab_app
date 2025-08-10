import 'package:flutter/material.dart';

import '../../../../core/entities/instruction.dart';

class InstructionDetailsSection extends StatelessWidget {
  final InstructionItem instruction;
  const InstructionDetailsSection({super.key, required this.instruction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                instruction.imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              instruction.title,
              style: theme.headlineSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Text(
              instruction.description,
              style: theme.bodyLarge,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            // ElevatedButton(onPressed: () {}, child: const Text('Acción')),
          ],
        ),
      ),
    );
  }
}
