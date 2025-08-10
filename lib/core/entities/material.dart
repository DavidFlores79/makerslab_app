enum MaterialItemType { internalRoute, externalUrl, modalBottomSheet, none }

class MaterialItem {
  final String title;
  final String description;
  final String qty;
  final String imagePath;
  final MaterialItemType actionType;
  final String? actionValue; // puede ser una ruta interna o una URL

  MaterialItem({
    required this.title,
    required this.description,
    required this.qty,
    required this.actionType,
    this.actionValue,
    imagePath,
  }) : imagePath = imagePath ?? 'assets/images/static/placeholder.png';
}
