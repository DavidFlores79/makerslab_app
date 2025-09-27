class TemperatureReading {
  final double temperature;
  final double humidity;
  final DateTime timestamp;
  TemperatureReading(this.temperature, this.humidity, [DateTime? ts])
    : timestamp = ts ?? DateTime.now();
}

TemperatureReading? parseDHTLine(String line) {
  // Limpia
  final s = line.trim();
  // Regex robusta: t<temp>h<hum>
  final reg = RegExp(r'^t([-+]?\d*\.?\d+)h([-+]?\d*\.?\d+)$');
  final m = reg.firstMatch(s);
  if (m == null) return null;
  final t = double.tryParse(m.group(1)!);
  final h = double.tryParse(m.group(2)!);
  if (t == null || h == null) return null;
  return TemperatureReading(t, h);
}
