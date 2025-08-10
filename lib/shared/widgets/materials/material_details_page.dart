import 'package:flutter/material.dart';

import '../../../core/entities/material.dart';
import '../../../theme/app_color.dart';

class MaterialDetailsPage extends StatelessWidget {
  final MaterialItem material;
  const MaterialDetailsPage({super.key, required this.material});

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
                material.imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    material.title,
                    style: theme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'x ${material.qty}',
                  style: theme.headlineSmall?.copyWith(
                    color: AppColors.gray500,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              material.description,
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
