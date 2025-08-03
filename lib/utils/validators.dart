class AppValidators {
  static bool isValidInvestmentAmount({
    required double amount,
    required double min,
    required double max,
  }) {
    return amount >= min && amount <= max;
  }
}
