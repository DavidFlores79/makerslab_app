import 'instruction.dart';
import 'material.dart';

class MainModule {
  final String title;
  final String description;
  final String? image; // puede ser una URL o un asset local
  final List<InstructionItem>?
  instructions; // puede ser una ruta interna o una URL
  final List<MaterialItem>? materials; // puede ser una ruta interna o una URL

  MainModule({
    required this.title,
    required this.description,
    required this.instructions,
    required this.materials,
    image,
  }) : image = image ?? 'assets/images/static/placeholder.png';
}
