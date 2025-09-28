import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:makerslab_app/shared/widgets/index.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/domain/entities/instruction.dart';
import '../../../../theme/app_color.dart';
import '../helpers/instruction_actions.dart';

class InstructionsSection extends StatelessWidget {
  final List<InstructionItem> instructions;
  const InstructionsSection({required this.instructions});

  @override
  Widget build(BuildContext context) {
    List<Color> buildGradientFromColor(Color base) {
      return [base, Color.alphaBlend(AppColors.black.withOpacity(0.1), base)];
    }

    return PxGenericListSection(
      title: 'Instrucciones',
      onViewAll:
          () => context.push(
            '/temperature/instruction_details',
            extra: instructions,
          ),
      onViewAllLabel: 'Ver todos',
      items: instructions,
      height: 250,
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, item) {
        return InkWell(
          onTap: () => handleInstructionItemTap(context, item),
          child: SizedBox(
            width: 140, // ancho consistente por ítem
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // alineación a la izquierda
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (item.imagePath != null && item.imagePath!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            item.imagePath!,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: buildGradientFromColor(AppColors.primary),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 40, // control de altura de la descripción
                  child: Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
