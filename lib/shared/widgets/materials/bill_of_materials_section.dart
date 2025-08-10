import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:makerslab_app/shared/widgets/index.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/entities/material.dart';
import '../../../theme/app_color.dart';

class BillOfMaterialsSection extends StatelessWidget {
  final List<MaterialItem> materials;
  const BillOfMaterialsSection({required this.materials});

  @override
  Widget build(BuildContext context) {
    return PxGenericListSection(
      title: 'Materiales',
      onViewAll: () {},
      items: materials,
      height: 180,
      scrollDirection: Axis.vertical,
      itemBuilder: (context, item) {
        final theme = Theme.of(context).textTheme;

        return ListTile(
          onTap: () => onMaterialItemTap(item, context),
          leading: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gray200,
              border: Border.all(color: AppColors.gray400, width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                item.imagePath,
                fit: BoxFit.cover,
                width: 48,
                height: 48,
              ),
            ),
          ),
          trailing: Text(
            'x ${item.qty}',
            style: theme.bodyLarge?.copyWith(
              color: AppColors.gray500,
              fontWeight: FontWeight.bold,
            ),
          ),
          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            item.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }

  Future<void> onMaterialItemTap(
    MaterialItem item,
    BuildContext context,
  ) async {
    switch (item.actionType) {
      case MaterialItemType.modalBottomSheet:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          useRootNavigator: true,
          isDismissible: true,
          enableDrag: true,
          clipBehavior: Clip.antiAlias,
          builder: (context) {
            return MaterialDetailsPage(material: item);
          },
        );
        break;
      case MaterialItemType.externalUrl:
        if (item.actionValue != null) {
          await launchUrl(
            Uri.parse(item.actionValue!),
            mode: LaunchMode.externalApplication,
          );
        }
        break;
      case MaterialItemType.none:
        // No hace nada o muestra mensaje
        break;
      case MaterialItemType.internalRoute:
        if (item.actionValue != null) {
          context.push(item.actionValue!);
        }
        break;
    }
  }
}
