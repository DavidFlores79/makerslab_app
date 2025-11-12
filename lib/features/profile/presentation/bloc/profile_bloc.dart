// ABOUTME: This file contains the ProfileBloc
// ABOUTME: Manages profile update business logic and state

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/usecases/update_profile.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UpdateProfile updateProfile;

  ProfileBloc({required this.updateProfile}) : super(ProfileInitial()) {
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
  }

  Future<void> _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    debugPrint('>>> UpdateProfileRequested event received');
    emit(ProfileLoading());

    final result = await updateProfile(
      userId: event.userId,
      name: event.name,
      email: event.email,
      phone: event.phone,
      image: event.image,
    );

    result.fold(
      (failure) {
        debugPrint('>>> Profile update failed: ${failure.message}');
        emit(ProfileUpdateFailure(error: failure.message));
      },
      (user) {
        debugPrint('>>> Profile update successful: ${user.name}');
        emit(ProfileUpdateSuccess(user: user));
      },
    );
  }
}
