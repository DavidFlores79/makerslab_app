// ABOUTME: This file contains the HeartbeatToggleWidget for the settings page
// ABOUTME: It displays a switch to enable or disable the global heartbeat (ping/pong) mechanism

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:makerslab_app/core/presentation/bloc/heartbeat/heartbeat_bloc.dart';
import 'package:makerslab_app/core/presentation/bloc/heartbeat/heartbeat_event.dart';
import 'package:makerslab_app/core/presentation/bloc/heartbeat/heartbeat_state.dart';
import 'package:makerslab_app/di/service_locator.dart';

class HeartbeatToggleWidget extends StatelessWidget {
  const HeartbeatToggleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<HeartbeatBloc>()..add(const LoadHeartbeatPreference()),
      child: const _HeartbeatToggleContent(),
    );
  }
}

class _HeartbeatToggleContent extends StatelessWidget {
  const _HeartbeatToggleContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<HeartbeatBloc, HeartbeatState>(
      builder: (context, state) {
        final isEnabled = switch (state) {
          HeartbeatLoaded(:final isEnabled) => isEnabled,
          _ => true, // Default enabled while loading
        };

        final isLoading = state is HeartbeatLoading;

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enviar/Recibir Heartbeat (ping)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEnabled
                        ? 'La app envía un ping cada 5 s para verificar la conexión'
                        : 'La desconexión se detecta por inactividad (45 s)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            isLoading
                ? const SizedBox(
                    width: 36,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Switch(
                    value: isEnabled,
                    onChanged: (value) {
                      context
                          .read<HeartbeatBloc>()
                          .add(ChangeHeartbeatEnabled(value));
                    },
                  ),
          ],
        );
      },
    );
  }
}
