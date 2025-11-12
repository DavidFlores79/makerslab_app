// ABOUTME: This file contains ProfileBloc events
// ABOUTME: Handles user profile update requests

abstract class ProfileEvent {}

class UpdateProfileRequested extends ProfileEvent {
  final String userId;
  final String? name;
  final String? email;
  final String? phone;
  final String? image;

  UpdateProfileRequested({
    required this.userId,
    this.name,
    this.email,
    this.phone,
    this.image,
  });
}
