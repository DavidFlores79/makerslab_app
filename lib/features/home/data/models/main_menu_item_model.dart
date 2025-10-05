import 'dart:convert';

import '../../domain/entities/main_menu_item.dart';

class MainMenuItemModel extends MainMenuItem {
  MainMenuItemModel({
    super.id,
    super.title,
    super.route,
    super.colorHex,
    super.assetPath,
    super.imageUrl,
    super.isStatic,
    super.priority,
  });

  factory MainMenuItemModel.fromRawJson(String str) =>
      MainMenuItemModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory MainMenuItemModel.fromJson(Map<String, dynamic> json) =>
      MainMenuItemModel(
        id: json["id"],
        title: json["title"],
        route: json["route"],
        colorHex: json["colorHex"],
        assetPath:
            (json['assetPath'] as String?)?.isEmpty ?? true
                ? null
                : json['assetPath'] as String?,
        imageUrl:
            (json['imageUrl'] as String?)?.isEmpty ?? true
                ? null
                : json['imageUrl'] as String?,
        isStatic: json['isStatic'] as bool? ?? false,
        priority: json['priority'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "route": route,
    "colorHex": colorHex,
    "assetPath": assetPath ?? '',
    "imageUrl": imageUrl ?? '',
    "isStatic": isStatic,
    "priority": priority,
  };

  /// Convierte desde la entidad de dominio
  factory MainMenuItemModel.fromDomain(MainMenuItemModel m) {
    return MainMenuItemModel(
      id: m.id,
      title: m.title,
      route: m.route,
      colorHex: m.colorHex,
      assetPath: m.assetPath,
      imageUrl: m.imageUrl,
      isStatic: m.isStatic,
      priority: m.priority,
    );
  }

  MainMenuItemModel toDomain() {
    return MainMenuItemModel(
      id: id,
      title: title,
      route: route,
      colorHex: colorHex,
      assetPath: assetPath,
      imageUrl: imageUrl,
      isStatic: isStatic,
      priority: priority,
    );
  }
}
