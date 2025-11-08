enum IntructionItemType { internalRoute, externalUrl, modalBottomSheet, none }

class InstructionItem {
  final String title;
  final String description;
  final String imagePath;
  final IntructionItemType actionType;
  final String? actionValue; // puede ser una ruta interna o una URL

  InstructionItem({
    required this.title,
    required this.description,
    required this.actionType,
    this.actionValue,
    imagePath,
  }) : imagePath = imagePath ?? 'assets/images/static/placeholder.png';
}
