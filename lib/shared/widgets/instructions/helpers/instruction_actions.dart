import 'package:flutter/material.dart';
import 'package:makerslab_app/shared/widgets/index.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/domain/entities/instruction.dart';

Future<void> handleInstructionItemTap(
  BuildContext context,
  InstructionItem item,
) async {
  switch (item.actionType) {
    case IntructionItemType.modalBottomSheet:
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        useRootNavigator: true,
        isDismissible: true,
        enableDrag: true,
        clipBehavior: Clip.antiAlias,
        builder: (_) => InstructionDetailsSection(instruction: item),
      );
      break;

    case IntructionItemType.externalUrl:
      if (item.actionValue != null) {
        await launchUrl(
          Uri.parse(item.actionValue!),
          mode: LaunchMode.externalApplication,
        );
      }
      break;

    case IntructionItemType.internalRoute:
      if (item.actionValue != null) {
        context.push(item.actionValue!);
      }
      break;

    case IntructionItemType.none:
      // No action
      break;
  }
}
