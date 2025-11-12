// ABOUTME: This file contains the RegisterState
// ABOUTME: It manages the registration form state including name, phone, country code, and password

class RegisterState {
  final int step;
  final String? phone;
  final String? confirmPhone;
  final String? countryCode;
  final String? password;
  final String? confirmPassword;
  final String? name;
  final bool isValid;

  const RegisterState({
    this.step = 0,
    this.phone,
    this.confirmPhone,
    this.countryCode,
    this.password,
    this.confirmPassword,
    this.name,
    this.isValid = false,
  });

  RegisterState copyWith({
    int? step,
    String? phone,
    String? confirmPhone,
    String? countryCode,
    String? password,
    String? confirmPassword,
    String? name,
    bool? isValid,
  }) {
    return RegisterState(
      step: step ?? this.step,
      phone: phone ?? this.phone,
      confirmPhone: confirmPhone ?? this.confirmPhone,
      countryCode: countryCode ?? this.countryCode,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      name: name ?? this.name,
      isValid: isValid ?? this.isValid,
    );
  }

  /// Returns the full phone number with country code (e.g., "+529991131753")
  String? get fullPhoneNumber {
    if (phone == null || phone!.isEmpty) return null;
    if (countryCode == null || countryCode!.isEmpty) return phone;

    // Ensure countryCode starts with '+'
    final code = countryCode!.startsWith('+') ? countryCode : '+$countryCode';
    return '$code$phone';
  }
}
