// ABOUTME: This file implements the ThemeBloc for managing theme state
// ABOUTME: It handles loading, saving, and computing theme mode based on user preference and system brightness

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:makerslab_app/core/domain/entities/theme_preference.dart';
import 'package:makerslab_app/core/domain/usecases/load_theme_preference_usecase.dart';
import 'package:makerslab_app/core/domain/usecases/save_theme_preference_usecase.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final LoadThemePreferenceUseCase loadThemeUseCase;
  final SaveThemePreferenceUseCase saveThemeUseCase;

  ThemeBloc({required this.loadThemeUseCase, required this.saveThemeUseCase})
    : super(const ThemeInitial()) {
    on<LoadThemePreference>(_onLoadThemePreference);
    on<ChangeThemeMode>(_onChangeThemeMode);
  }

  Future<void> _onLoadThemePreference(
    LoadThemePreference event,
    Emitter<ThemeState> emit,
  ) async {
    emit(const ThemeLoading());

    final result = await loadThemeUseCase();

    result.fold(
      (failure) {
        // If loading fails, default to system theme
        final isDark = _isSystemDarkMode();
        emit(ThemeLoaded(mode: ThemePreference.system, isDarkMode: isDark));
      },
      (preference) {
        final isDark = _computeIsDarkMode(preference);
        emit(ThemeLoaded(mode: preference, isDarkMode: isDark));
      },
    );
  }

  Future<void> _onChangeThemeMode(
    ChangeThemeMode event,
    Emitter<ThemeState> emit,
  ) async {
    // Save the new preference
    final result = await saveThemeUseCase(event.mode);

    result.fold(
      (failure) {
        // If save fails, still update UI but keep trying
        final isDark = _computeIsDarkMode(event.mode);
        emit(ThemeLoaded(mode: event.mode, isDarkMode: isDark));
      },
      (_) {
        // Successfully saved, update UI
        final isDark = _computeIsDarkMode(event.mode);
        emit(ThemeLoaded(mode: event.mode, isDarkMode: isDark));
      },
    );
  }

  /// Computes whether dark mode should be active based on preference
  bool _computeIsDarkMode(ThemePreference preference) {
    return switch (preference) {
      ThemePreference.light => false,
      ThemePreference.dark => true,
      ThemePreference.system => _isSystemDarkMode(),
    };
  }

  /// Checks if system is in dark mode
  bool _isSystemDarkMode() {
    final brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }
}
