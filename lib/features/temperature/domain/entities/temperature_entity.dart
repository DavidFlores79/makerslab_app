class Temperature {
  final double celsius;
  final double humidity;
  final DateTime timestamp;

  Temperature({
    required this.celsius,
    required this.humidity,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
