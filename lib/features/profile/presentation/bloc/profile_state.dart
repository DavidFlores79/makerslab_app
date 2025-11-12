// ABOUTME: This file contains ProfileBloc states
// ABOUTME: Represents different states during profile operations

import '../../../../core/domain/entities/user.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileUpdateSuccess extends ProfileState {
  final User user;

  ProfileUpdateSuccess({required this.user});
}

class ProfileUpdateFailure extends ProfileState {
  final String error;

  ProfileUpdateFailure({required this.error});
}
