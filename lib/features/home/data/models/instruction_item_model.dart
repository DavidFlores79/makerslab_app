// ABOUTME: Data model for InstructionItem entity with JSON serialization
// ABOUTME: Handles conversion between JSON and domain entity for module instructions

import 'package:makerslab_app/features/home/domain/entities/instruction_item.dart';

class InstructionItemModel extends InstructionItem {
  InstructionItemModel({
    required super.title,
    required super.description,
    required super.actionType,
    super.actionValue,
    super.imagePath,
  });

  factory InstructionItemModel.fromJson(Map<String, dynamic> json) {
    return InstructionItemModel(
      title: json['title'] as String,
      description: json['description'] as String,
      imagePath: json['imagePath'] as String?,
      actionType: _actionTypeFromString(json['actionType'] as String),
      actionValue: json['actionValue'] as String?,
    );
  }

  factory InstructionItemModel.fromEntity(InstructionItem entity) {
    return InstructionItemModel(
      title: entity.title,
      description: entity.description,
      imagePath: entity.imagePath,
      actionType: entity.actionType,
      actionValue: entity.actionValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'imagePath': imagePath,
      'actionType': _actionTypeToString(actionType),
      if (actionValue != null) 'actionValue': actionValue,
    };
  }

  static IntructionItemType _actionTypeFromString(String value) {
    switch (value.toLowerCase()) {
      case 'internalroute':
        return IntructionItemType.internalRoute;
      case 'externalurl':
        return IntructionItemType.externalUrl;
      case 'modalbottomsheet':
        return IntructionItemType.modalBottomSheet;
      case 'none':
      default:
        return IntructionItemType.none;
    }
  }

  static String _actionTypeToString(IntructionItemType type) {
    switch (type) {
      case IntructionItemType.internalRoute:
        return 'internalRoute';
      case IntructionItemType.externalUrl:
        return 'externalUrl';
      case IntructionItemType.modalBottomSheet:
        return 'modalBottomSheet';
      case IntructionItemType.none:
        return 'none';
    }
  }
}
