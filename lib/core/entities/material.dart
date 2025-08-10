enum MaterialItemType { internalRoute, externalUrl, none }

class MaterialItem {
  final String title;
  final String description;
  final MaterialItemType actionType;
  final String? actionValue; // puede ser una ruta interna o una URL

  MaterialItem({
    required this.title,
    required this.description,
    required this.actionType,
    this.actionValue,
  });
}
