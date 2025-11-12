// ABOUTME: This file contains the RegisterCubit
// ABOUTME: It manages registration form state and validation

import 'package:flutter_bloc/flutter_bloc.dart';

import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit() : super(const RegisterState());

  void updatePhone(String phone) {
    final newState = state.copyWith(phone: phone);
    emit(newState.copyWith(isValid: _validate(newState)));
  }

  void updateConfirmPhone(String confirmPhone) {
    final newState = state.copyWith(confirmPhone: confirmPhone);
    emit(newState.copyWith(isValid: _validate(newState)));
  }

  void updatePassword(String password) {
    final newState = state.copyWith(password: password);
    emit(newState.copyWith(isValid: _validate(newState)));
  }

  void updateConfirmPassword(String confirmPassword) {
    final newState = state.copyWith(confirmPassword: confirmPassword);
    emit(newState.copyWith(isValid: _validate(newState)));
  }

  void updateName(String name) {
    final newState = state.copyWith(name: name);
    emit(newState.copyWith(isValid: _validate(newState)));
  }

  void nextStep() => emit(state.copyWith(step: state.step + 1));
  void prevStep() => emit(state.copyWith(step: state.step - 1));
  void updateStep(int step) => emit(state.copyWith(step: step));
  void reset() => emit(const RegisterState());

  bool _validate(RegisterState s) {
    return (s.phone?.isNotEmpty ?? false) &&
        (s.password?.isNotEmpty ?? false) &&
        (s.confirmPassword == s.password) &&
        (s.name?.isNotEmpty ?? false);
  }
}
