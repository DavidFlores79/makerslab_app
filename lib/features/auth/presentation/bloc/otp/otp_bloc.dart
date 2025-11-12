// ABOUTME: This file contains the OTP BLoC for handling OTP verification
// ABOUTME: Supports both legacy and new registration flows with timer management

import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/failure.dart';
import '../../../data/models/login_response_model.dart';
import '../../../domain/usecases/resend_sign_up_code.dart';
import '../../../domain/usecases/confirm_sign_up.dart';
import '../../../domain/usecases/verify_registration.dart';
import '../../../domain/usecases/resend_registration_code.dart';
import 'otp_event.dart';
import 'otp_state.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  final ResendSignUpCode resendSignUpCode;
  final ConfirmSignUp confirmSignUp;
  final VerifyRegistration verifyRegistration;
  final ResendRegistrationCode resendRegistrationCode;

  StreamSubscription<int>? _tickerSub;

  OtpBloc({
    required this.resendSignUpCode,
    required this.confirmSignUp,
    required this.verifyRegistration,
    required this.resendRegistrationCode,
  }) : super(OtpInitial(secondsLeft: 300)) {
    on<OtpStartTimer>(_onStarted);
    on<OtpTick>(_onTicked);
    on<OtpCodeChanged>(_onCodeChanged);
    on<OtpResendPressed>(_onResendPressed);
    on<OtpConfirmPressed>(_onConfirmPressed);
    on<OtpVerifyRegistration>(_onVerifyRegistration);
    on<OtpResendRegistrationCode>(_onResendRegistrationCode);
  }

  void _onStarted(OtpStartTimer event, Emitter<OtpState> emit) {
    _tickerSub?.cancel();
    final seconds = event.seconds;
    debugPrint('>>> Otp timer start: $seconds segundos');
    // Stream that emits remaining seconds
    final stream = Stream.periodic(
      const Duration(seconds: 1),
      (count) => seconds - count - 1,
    ).take(seconds);
    _tickerSub = stream.listen(
      (secondsLeft) {
        add(OtpTick(secondsLeft));
      },
      onDone: () {
        add(OtpTick(0));
      },
    );
  }

  void _onTicked(OtpTick event, Emitter<OtpState> emit) {
    final canResend = event.secondsLeft == 0;
    final currentCode = (state is OtpInitial) ? (state as OtpInitial).code : '';
    emit(
      OtpInitial(
        secondsLeft: event.secondsLeft,
        code: currentCode,
        canResend: canResend,
      ),
    );
  }

  void _onCodeChanged(OtpCodeChanged event, Emitter<OtpState> emit) {
    if (state is OtpInitial) {
      final s = state as OtpInitial;
      emit(
        OtpInitial(
          secondsLeft: s.secondsLeft,
          code: event.code,
          canResend: s.canResend,
        ),
      );
    } else {
      emit(OtpInitial(secondsLeft: 60, code: event.code, canResend: false));
    }
  }

  Future<void> _onResendPressed(
    OtpResendPressed event,
    Emitter<OtpState> emit,
  ) async {
    debugPrint(
      '>>> OtpResendPressed: enviando petición de reenvío para ${event.id}',
    );
    emit(OtpLoading());
    try {
      final Either<Failure, void> result = await resendSignUpCode.call(
        userId: event.id,
      );
      result.fold(
        (failure) {
          debugPrint('>>> resendSignUpCode falló: ${failure.message}');
          emit(OtpFailure(failure.message));
        },
        (_) {
          debugPrint('>>> resendSignUpCode ok (fire-and-forget style)');
          emit(OtpResendSent());
          // reinicia timer
          add(OtpStartTimer(seconds: 60));
        },
      );
    } catch (e) {
      debugPrint('>>> resendSignUpCode excepción: $e');
      emit(OtpFailure(e.toString()));
    }
  }

  Future<void> _onConfirmPressed(
    OtpConfirmPressed event,
    Emitter<OtpState> emit,
  ) async {
    debugPrint(
      '>>> OtpConfirmPressed para userId: ${event.id} con código: ${event.code}',
    );
    if (state is! OtpInitial) {
      emit(OtpLoading());
    } else {
      emit(OtpLoading());
    }

    try {
      debugPrint('>>> Código a enviar: ${event.code}');
      final Either<Failure, LoginResponseModel> result = await confirmSignUp
          .call(userId: event.id, code: event.code);

      result.fold(
        (failure) {
          debugPrint('>>> confirmSignUp falló: ${failure.message}');
          emit(OtpFailure(failure.message));
        },
        (payload) {
          debugPrint('>>> confirmSignUp ok, payload recibido');
          final token = payload.jwt ?? '';
          final user = payload.data;
          if (user != null) {
            emit(OtpConfirmSuccess(token: token, user: user));
          } else {
            emit(OtpFailure('User information is missing.'));
          }
        },
      );
    } catch (e) {
      debugPrint('>>> confirmSignUp excepción: $e');
      emit(OtpFailure(e.toString()));
    }
  }

  Future<void> _onVerifyRegistration(
    OtpVerifyRegistration event,
    Emitter<OtpState> emit,
  ) async {
    debugPrint(
      '>>> OtpVerifyRegistration for registrationId: ${event.registrationId} with OTP: ${event.otp}',
    );
    emit(OtpLoading());

    try {
      final Either<Failure, dynamic> result = await verifyRegistration.call(
        registrationId: event.registrationId,
        otp: event.otp,
      );

      result.fold(
        (failure) {
          debugPrint('>>> verifyRegistration failed: ${failure.message}');
          emit(OtpFailure(failure.message));
        },
        (user) {
          debugPrint('>>> verifyRegistration success');
          emit(OtpRegistrationSuccess(user: user));
        },
      );
    } catch (e) {
      debugPrint('>>> verifyRegistration exception: $e');
      emit(OtpFailure(e.toString()));
    }
  }

  Future<void> _onResendRegistrationCode(
    OtpResendRegistrationCode event,
    Emitter<OtpState> emit,
  ) async {
    debugPrint(
      '>>> OtpResendRegistrationCode for registrationId: ${event.registrationId}',
    );
    emit(OtpLoading());

    try {
      final Either<Failure, void> result = await resendRegistrationCode.call(
        registrationId: event.registrationId,
      );

      result.fold(
        (failure) {
          debugPrint('>>> resendRegistrationCode failed: ${failure.message}');
          emit(OtpFailure(failure.message));
        },
        (_) {
          debugPrint('>>> resendRegistrationCode success');
          emit(OtpResendSent());
          // Restart timer (5 minutes)
          add(OtpStartTimer(seconds: 300));
        },
      );
    } catch (e) {
      debugPrint('>>> resendRegistrationCode exception: $e');
      emit(OtpFailure(e.toString()));
    }
  }

  @override
  Future<void> close() {
    debugPrint('>>> OtpBloc closed');
    _tickerSub?.cancel();
    return super.close();
  }
}
