// ABOUTME: Data model for MaterialItem entity with JSON serialization
// ABOUTME: Handles conversion between JSON and domain entity for module materials/components

import 'package:makerslab_app/features/home/domain/entities/material_item.dart';

class MaterialItemModel extends MaterialItem {
  MaterialItemModel({
    required super.title,
    required super.description,
    required super.qty,
    required super.actionType,
    super.actionValue,
    super.imagePath,
  });

  factory MaterialItemModel.fromJson(Map<String, dynamic> json) {
    return MaterialItemModel(
      title: json['title'] as String,
      description: json['description'] as String,
      qty: json['qty'] as String,
      imagePath: json['imagePath'] as String?,
      actionType: _actionTypeFromString(json['actionType'] as String),
      actionValue: json['actionValue'] as String?,
    );
  }

  factory MaterialItemModel.fromEntity(MaterialItem entity) {
    return MaterialItemModel(
      title: entity.title,
      description: entity.description,
      qty: entity.qty,
      imagePath: entity.imagePath,
      actionType: entity.actionType,
      actionValue: entity.actionValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'qty': qty,
      'imagePath': imagePath,
      'actionType': _actionTypeToString(actionType),
      if (actionValue != null) 'actionValue': actionValue,
    };
  }

  static MaterialItemType _actionTypeFromString(String value) {
    switch (value.toLowerCase()) {
      case 'internalroute':
        return MaterialItemType.internalRoute;
      case 'externalurl':
        return MaterialItemType.externalUrl;
      case 'modalbottomsheet':
        return MaterialItemType.modalBottomSheet;
      case 'none':
      default:
        return MaterialItemType.none;
    }
  }

  static String _actionTypeToString(MaterialItemType type) {
    switch (type) {
      case MaterialItemType.internalRoute:
        return 'internalRoute';
      case MaterialItemType.externalUrl:
        return 'externalUrl';
      case MaterialItemType.modalBottomSheet:
        return 'modalBottomSheet';
      case MaterialItemType.none:
        return 'none';
    }
  }
}
