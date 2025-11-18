// ABOUTME: This file contains the PrivacyPolicyPage
// ABOUTME: Displays the privacy policy document with Markdown support

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../di/service_locator.dart';
import '../../../../shared/widgets/index.dart';
import '../bloc/legal_bloc.dart';
import '../bloc/legal_event.dart';
import '../bloc/legal_state.dart';

class PrivacyPolicyPage extends StatelessWidget {
  static const String routeName = '/privacy-policy';

  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode == 'es' ? 'es' : 'en';

    return BlocProvider(
      create:
          (_) =>
              getIt<LegalBloc>()..add(
                LoadLegalDocument(type: 'privacy_policy', language: language),
              ),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: const PxBackAppBar(backLabel: 'Back'),
        body: BlocBuilder<LegalBloc, LegalState>(
          builder: (context, state) {
            if (state is LegalLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is LegalFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar el documento',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.error,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<LegalBloc>().add(
                            LoadLegalDocument(
                              type: 'privacy_policy',
                              language: language,
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is LegalLoaded) {
              final document = state.document;
              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title ?? 'Política de Privacidad',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (document.version != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Versión ${document.version}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (document.effectiveDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Vigente desde ${_formatDate(document.effectiveDate!)}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      MarkdownBody(
                        data: document.content ?? '',
                        styleSheet: MarkdownStyleSheet(
                          p: Theme.of(context).textTheme.bodyMedium,
                          h1: Theme.of(context).textTheme.headlineLarge,
                          h2: Theme.of(context).textTheme.headlineMedium,
                          h3: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
