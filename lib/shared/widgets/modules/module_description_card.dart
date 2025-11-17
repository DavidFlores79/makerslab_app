// ABOUTME: Module description card with learning objectives and metadata
// ABOUTME: Shows what users will learn, estimated time, and difficulty level

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../../features/home/domain/entities/module_detail.dart';
import '../../../theme/app_color.dart';

class ModuleDescriptionCard extends StatelessWidget {
  final ModuleDetail moduleDetail;

  const ModuleDescriptionCard({super.key, required this.moduleDetail});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Qué aprenderás" section header
            Row(
              children: [
                Icon(Symbols.school, size: 24, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Qué aprenderás',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Module description
            Text(
              moduleDetail.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.gray700,
              ),
            ),

            const SizedBox(height: 16),

            // Metadata badges (time and difficulty)
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (moduleDetail.estimatedTime != null)
                  _MetadataBadge(
                    icon: Symbols.schedule,
                    label: moduleDetail.estimatedTime!,
                    color: AppColors.primary,
                  ),
                if (moduleDetail.difficultyLevel != null)
                  _MetadataBadge(
                    icon: Symbols.signal_cellular_alt,
                    label: moduleDetail.difficultyLevel!,
                    color: _getDifficultyColor(moduleDetail.difficultyLevel!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get color based on difficulty level
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'principiante':
        return Colors.green;
      case 'intermedio':
        return Colors.orange;
      case 'avanzado':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }
}

/// Metadata badge widget for time and difficulty
class _MetadataBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetadataBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
