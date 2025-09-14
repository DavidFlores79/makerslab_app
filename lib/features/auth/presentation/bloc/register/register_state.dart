class RegisterState {
  final int step;
  final String? phone;
  final String? confirmPhone;
  final String? password;
  final String? confirmPassword;
  final String? firstName;
  final String? firstSurname;
  final String? secondSurname;
  final bool isValid;

  const RegisterState({
    this.step = 0,
    this.phone,
    this.confirmPhone,
    this.password,
    this.confirmPassword,
    this.firstName,
    this.firstSurname,
    this.secondSurname,
    this.isValid = false,
  });

  RegisterState copyWith({
    int? step,
    String? phone,
    String? confirmPhone,
    String? password,
    String? confirmPassword,
    String? firstName,
    String? firstSurname,
    String? secondSurname,
    bool? isValid,
  }) {
    return RegisterState(
      step: step ?? this.step,
      phone: phone ?? this.phone,
      confirmPhone: confirmPhone ?? this.confirmPhone,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      firstName: firstName ?? this.firstName,
      firstSurname: firstSurname ?? this.firstSurname,
      secondSurname: secondSurname ?? this.secondSurname,
      isValid: isValid ?? this.isValid,
    );
  }
}
