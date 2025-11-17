// ABOUTME: Gamepad robot control module page with dynamic module detail loading
// ABOUTME: Uses HomeBloc for lazy loading module details from JSON datasource

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/home/presentation/bloc/home_bloc.dart';
import '../../../../features/home/presentation/bloc/home_event.dart';
import '../../../../features/home/presentation/bloc/home_state.dart';
import '../../../../features/home/domain/entities/module_detail.dart';
import '../../../../shared/widgets/index.dart';
import '../../../../shared/widgets/chat/px_chatbot_floating_button.dart';

class GamepadPage extends StatelessWidget {
  static const String routeName = '/gamepad';
  static const String moduleId = 'gamepad';

  const GamepadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        // Trigger lazy load if not already loaded
        if (state.getModuleDetail(moduleId) == null &&
            !state.isLoadingModuleDetails) {
          context.read<HomeBloc>().add(LoadModuleDetail(moduleId: moduleId));
        }

        final moduleDetail = state.getModuleDetail(moduleId);

        return Scaffold(
          body: SafeArea(child: _buildBody(context, state, moduleDetail)),
          floatingActionButton: PxChatBotFloatingButton(
            moduleKey: moduleDetail?.chatModuleKey ?? 'gamepad',
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    HomeState state,
    ModuleDetail? moduleDetail,
  ) {
    // Loading state
    if (moduleDetail == null && state.isLoadingModuleDetails) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (moduleDetail == null && state.moduleDetailError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              state.moduleDetailError!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed:
                  () => context.read<HomeBloc>().add(
                    LoadModuleDetail(moduleId: moduleId),
                  ),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Success state
    if (moduleDetail != null) {
      return CustomScrollView(
        slivers: [
          MainSliverBackAppBar(
            assetImagePath:
                moduleDetail.image ?? 'assets/images/static/placeholder.png',
            centerTitle: true,
            backLabel: moduleDetail.title,
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),
              BuildMainContent(moduleDetail: moduleDetail),
            ]),
          ),
        ],
      );
    }

    // Fallback (should never reach here)
    return const Center(child: Text('No se pudo cargar el módulo'));
  }
}
