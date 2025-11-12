// ABOUTME: This file defines events for the ThemeBloc state management
// ABOUTME: It includes events for loading and changing theme preferences

import 'package:equatable/equatable.dart';

import 'package:makerslab_app/core/domain/entities/theme_preference.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load the saved theme preference from storage
class LoadThemePreference extends ThemeEvent {
  const LoadThemePreference();
}

/// Event to change and save the theme mode
class ChangeThemeMode extends ThemeEvent {
  final ThemePreference mode;

  const ChangeThemeMode(this.mode);

  @override
  List<Object?> get props => [mode];
}
