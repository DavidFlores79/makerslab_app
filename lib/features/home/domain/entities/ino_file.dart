// ABOUTME: Domain entity representing a platform-specific Arduino INO file
// ABOUTME: Supports multiple platforms (ESP32, Arduino UNO) per module

enum InoPlatform {
  esp32('ESP32'),
  arduinoUno('Arduino UNO');

  final String displayName;
  const InoPlatform(this.displayName);

  static InoPlatform fromString(String value) {
    switch (value.toLowerCase()) {
      case 'esp32':
        return InoPlatform.esp32;
      case 'arduino uno':
        return InoPlatform.arduinoUno;
      default:
        throw ArgumentError('Unknown platform: $value');
    }
  }
}

class InoFile {
  final InoPlatform platform;
  final String fileName;
  final String filePath;
  final String? description;

  const InoFile({
    required this.platform,
    required this.fileName,
    required this.filePath,
    this.description,
  });
}
