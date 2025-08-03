class Remittance {
  final String id;
  final String senderName;
  final double amount;
  final DateTime date;
  final String status;

  Remittance({
    required this.id,
    required this.senderName,
    required this.amount,
    required this.date,
    required this.status,
  });
}
