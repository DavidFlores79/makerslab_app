import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/check_session.dart';
import '../../domain/usecases/get_user_from_cache.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/logout_user.dart';
import '../../domain/usecases/register_user.dart';
import '../../domain/usecases/change_password.dart';
import '../../domain/usecases/forgot_password.dart';
import '../../domain/usecases/signin_with_phone.dart';
import '../../domain/usecases/update_profile.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUser loginUser;
  final SigninWithPhone signinWithPhone;
  final RegisterUser registerUser;
  final ChangePassword changePassword;
  final ForgotPassword forgotPassword;
  final CheckSession checkSession;
  final GetUserFromCache getUserFromCache;
  final LogoutUser logoutUser;
  final UpdateProfile updateProfile;

  AuthBloc({
    required this.loginUser,
    required this.signinWithPhone,
    required this.registerUser,
    required this.changePassword,
    required this.forgotPassword,
    required this.checkSession,
    required this.getUserFromCache,
    required this.logoutUser,
    required this.updateProfile,
  }) : super(AuthInitial()) {
    debugPrint('>>> AuthBloc creado');
    on<LoginRequested>(_onLoginRequested);
    on<SigninWithPhoneRequested>(_onSigninWithPhoneRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<ChangePasswordRequested>(_onChangePasswordRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LogoutRequested>(_onLogoutRequested);
    on<RegistrationConfirmed>(_onRegistrationConfirmed);
    on<AuthUserChanged>(_onAuthUserChanged);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
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

  Future<void> _onSigninWithPhoneRequested(
    SigninWithPhoneRequested event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint(">>> SigninWithPhoneRequested event recibido");
    emit(AuthLoading());

    final result = await signinWithPhone(event.phone, event.password);
    debugPrint(">>> signinWithPhone result: $result");

    result.fold(
      (failure) {
        debugPrint(">>> signinWithPhone falló: ${failure.message}");
        emit(AuthError(failure.message));
      },
      (user) {
        debugPrint(">>> signinWithPhone exitoso: ${user.phone}");
        emit(Authenticated(user: user));
      },
    );
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await registerUser(
      name: event.name,
      phone: event.phone,
      password: event.password,
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
    final result = await changePassword(
      event.confirmPassword,
      event.newPassword,
    );

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
    final result = await forgotPassword(event.phone);

    result.fold(
      (failure) => emit(ForgotPasswordFailure(failure.message)),
      (data) => emit(
        ForgotPasswordSuccess(
          message: data.message ?? '',
          userId: data.resetRequestId ?? '',
        ),
      ),
    );
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
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
    result.fold((failure) => emit(AuthError(failure.message)), (_) {
      emit(SessionClosed());
      emit(Unauthenticated());
    });
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

  Future<void> _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint(">>> UpdateProfileRequested event recibido");
    emit(AuthLoading());

    final result = await updateProfile(
      userId: event.userId,
      name: event.name,
      email: event.email,
      phone: event.phone,
      image: event.image,
    );

    result.fold(
      (failure) {
        debugPrint(">>> updateProfile falló: ${failure.message}");
        emit(AuthError(failure.message));
      },
      (user) {
        debugPrint(">>> updateProfile exitoso: ${user.name}");
        emit(Authenticated(user: user));
      },
    );
  }
}
