enum IntructionType { internalRoute, externalUrl, none }

class Instruction {
  final String title;
  final String description;
  final IntructionType actionType;
  final String? actionValue; // puede ser una ruta interna o una URL

  Instruction({
    required this.title,
    required this.description,
    required this.actionType,
    this.actionValue,
  });
}
