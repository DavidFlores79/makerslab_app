// ABOUTME: This file defines states for the ThemeBloc state management
// ABOUTME: It includes states for initial, loading, loaded theme preferences

import 'package:equatable/equatable.dart';

import 'package:makerslab_app/core/domain/entities/theme_preference.dart';

abstract class ThemeState extends Equatable {
  const ThemeState();

  @override
  List<Object?> get props => [];
}

/// Initial state before theme preference is loaded
class ThemeInitial extends ThemeState {
  const ThemeInitial();
}

/// State while theme preference is being loaded
class ThemeLoading extends ThemeState {
  const ThemeLoading();
}

/// State when theme preference is loaded successfully
class ThemeLoaded extends ThemeState {
  final ThemePreference mode;
  final bool isDarkMode;

  const ThemeLoaded({
    required this.mode,
    required this.isDarkMode,
  });

  @override
  List<Object?> get props => [mode, isDarkMode];
}
