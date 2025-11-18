// ABOUTME: This file contains the LegalBloc
// ABOUTME: Manages legal document fetching and state management

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_legal_document.dart';
import 'legal_event.dart';
import 'legal_state.dart';

class LegalBloc extends Bloc<LegalEvent, LegalState> {
  final GetLegalDocument getLegalDocument;

  LegalBloc({required this.getLegalDocument}) : super(LegalInitial()) {
    on<LoadLegalDocument>(_onLoadLegalDocument);
  }

  Future<void> _onLoadLegalDocument(
    LoadLegalDocument event,
    Emitter<LegalState> emit,
  ) async {
    debugPrint(
      '>>> LoadLegalDocument event received: ${event.type} (${event.language})',
    );
    emit(LegalLoading());

    final result = await getLegalDocument(
      type: event.type,
      language: event.language,
    );

    result.fold(
      (failure) {
        debugPrint('>>> Legal document load failed: ${failure.message}');
        emit(LegalFailure(error: failure.message));
      },
      (document) {
        debugPrint('>>> Legal document loaded: ${document.title}');
        emit(LegalLoaded(document: document));
      },
    );
  }
}
