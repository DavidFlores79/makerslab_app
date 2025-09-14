import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/check_session.dart';
import '../../domain/usecases/get_user_from_cache.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/logout_user.dart';
import '../../domain/usecases/register_user.dart';
import '../../domain/usecases/change_password.dart';
import '../../domain/usecases/forgot_password.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUser loginUser;
  final RegisterUser registerUser;
  final ChangePassword changePassword;
  final ForgotPassword forgotPassword;
  final CheckSession checkSession;
  final GetUserFromCache getUserFromCache;
  final LogoutUser logoutUser;

  AuthBloc({
    required this.loginUser,
    required this.registerUser,
    required this.changePassword,
    required this.forgotPassword,
    required this.checkSession,
    required this.getUserFromCache,
    required this.logoutUser,
  }) : super(AuthInitial()) {
    debugPrint('>>> AuthBloc creado');
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<ChangePasswordRequested>(_onChangePasswordRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LogoutRequested>(_onLogoutRequested);
    on<RegistrationConfirmed>(_onRegistrationConfirmed);
    on<AuthUserChanged>(_onAuthUserChanged);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    // emit(AuthLoading());

    // final result = await loginUser(event.email, event.password);

    // result.fold((failure) => emit(AuthError(failure.message)), (user) {
    //   emit(Unauthenticated());
    //   emit(Authenticated(user: user));
    // });
    debugPrint(">>> LoginRequested event recibido");
    emit(AuthLoading());

    final result = await loginUser(event.email, event.password);
    debugPrint(">>> loginUser result: $result");

    result.fold(
      (failure) {
        debugPrint(">>> login falló: ${failure.message}");
        emit(AuthError(failure.message));
      },
      (user) {
        debugPrint(">>> login exitoso: ${user.name}");
        emit(Authenticated(user: user));
      },
    );
  }

  // Future<void> _onRegisterRequested(
  //   RegisterRequested event,
  //   Emitter<AuthState> emit,
  // ) async {
  //   emit(AuthLoading());
  //   final result = await registerUser(
  //     firstName: event.firstName,
  //     firstSurname: event.firstSurname,
  //     secondSurname: event.secondSurname,
  //     phone: event.phone,
  //     password: event.password,
  //     confirmPassword: event.confirmPassword,
  //   );

  //   result.fold(
  //     (failure) => emit(AuthError(failure.message)),
  //     (user) => emit(Authenticated(user: user)),
  //   );
  // }
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await registerUser(
      firstName: event.firstName,
      firstSurname: event.firstSurname,
      secondSurname: event.secondSurname,
      phone: event.phone,
      password: event.password,
      confirmPassword: event.confirmPassword,
    );

    result.fold(
      (failure) {
        debugPrint('>>> Registro falló: ${failure.message}');
        emit(AuthError(failure.message));
      },
      (user) {
        debugPrint('>>> Registro ok; pasar a OTP para userId: ${user.id}');
        emit(
          RegistrationPending(userId: user.id ?? '', phone: user.phone ?? ''),
        );
      },
    );
  }

  // nuevo handler:
  Future<void> _onRegistrationConfirmed(
    RegistrationConfirmed event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint(
      '>>> _onRegistrationConfirmed: recibiendo token + user from OTP confirm',
    );
    emit(AuthLoading());
    try {
      emit(Authenticated(user: event.user));
    } catch (e) {
      debugPrint('>>> Error al procesar confirmación: $e');
      emit(AuthError('Error al procesar confirmación'));
    }
  }

  Future<void> _onChangePasswordRequested(
    ChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await changePassword(event.oldPassword, event.newPassword);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthSuccess()),
    );
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await forgotPassword(event.email);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthSuccess()),
    );
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    // final hasSession = await checkSession();
    // if (hasSession) {
    //   final result = await getUserFromCache();
    //   result.fold(
    //     (failure) => emit(AuthError(failure.message)),
    //     (user) => emit(Authenticated(user: user)),
    //   );
    // } else {
    //   emit(Unauthenticated());
    // }
    debugPrint(">>> CheckAuthStatus ejecutado");
    final hasSession = await checkSession();
    if (hasSession) {
      final result = await getUserFromCache();
      result.fold(
        (failure) {
          debugPrint(">>> getUserFromCache falló");
          emit(AuthError(failure.message));
        },
        (user) {
          debugPrint(">>> usuario en cache: ${user.name}");
          emit(Authenticated(user: user));
        },
      );
    } else {
      debugPrint(">>> no hay sesión activa");
      // emit(Unauthenticated());
      if (state is! Authenticated) {
        emit(Unauthenticated());
      }
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    // Borra tokens y usuario en caché
    final result = await logoutUser(); // inyectado UseCase
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(Unauthenticated()),
    );
  }

  Future<void> _onAuthUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint(">>> AuthUserChanged event recibido");
    if (event.user != null) {
      emit(Authenticated(user: event.user!));
    } else {
      emit(Unauthenticated());
    }
  }
}
