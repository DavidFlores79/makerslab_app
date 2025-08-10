import 'instruction.dart';
import 'material.dart';

class MainModule {
  final String title;
  final String description;
  final String? image; // puede ser una URL o un asset local
  final List<Instruction>? instructions; // puede ser una ruta interna o una URL
  final List<MaterialItem>? materials; // puede ser una ruta interna o una URL

  MainModule({
    required this.title,
    required this.description,
    required this.instructions,
    required this.materials,
    this.image,
  });
}
