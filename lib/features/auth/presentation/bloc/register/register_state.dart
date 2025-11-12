// ABOUTME: This file contains the RegisterState
// ABOUTME: It manages the registration form state including name, phone, and password

class RegisterState {
  final int step;
  final String? phone;
  final String? confirmPhone;
  final String? password;
  final String? confirmPassword;
  final String? name;
  final bool isValid;

  const RegisterState({
    this.step = 0,
    this.phone,
    this.confirmPhone,
    this.password,
    this.confirmPassword,
    this.name,
    this.isValid = false,
  });

  RegisterState copyWith({
    int? step,
    String? phone,
    String? confirmPhone,
    String? password,
    String? confirmPassword,
    String? name,
    bool? isValid,
  }) {
    return RegisterState(
      step: step ?? this.step,
      phone: phone ?? this.phone,
      confirmPhone: confirmPhone ?? this.confirmPhone,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      name: name ?? this.name,
      isValid: isValid ?? this.isValid,
    );
  }
}
