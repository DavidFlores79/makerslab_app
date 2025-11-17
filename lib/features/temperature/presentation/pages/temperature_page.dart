// ABOUTME: Temperature sensor module page with dynamic module detail loading
// ABOUTME: Uses HomeBloc for lazy loading module details from JSON datasource

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/home/presentation/bloc/home_bloc.dart';
import '../../../../features/home/presentation/bloc/home_event.dart';
import '../../../../features/home/presentation/bloc/home_state.dart';
import '../../../../features/home/domain/entities/module_detail.dart';
import '../../../../features/home/domain/entities/platform_config.dart';
import '../../../../core/domain/usecases/share_file_usecase.dart';
import '../../../../core/ui/snackbar_service.dart';
import '../../../../di/service_locator.dart';
import '../../../../shared/widgets/index.dart';
import '../../../../shared/widgets/chat/px_chatbot_floating_button.dart';

class TemperaturePage extends StatefulWidget {
  static const String routeName = '/temperature';
  static const String moduleId = 'temperature';

  const TemperaturePage({super.key});

  @override
  State<TemperaturePage> createState() => _TemperaturePageState();
}

class _TemperaturePageState extends State<TemperaturePage> {
  final ScrollController _scrollController = ScrollController();
  bool _showActionBar = false;
  PlatformConfig? _currentPlatformConfig;

  static const double _scrollThreshold = 250.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > _scrollThreshold;

    if (shouldShow != _showActionBar) {
      setState(() {
        _showActionBar = shouldShow;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        // Trigger lazy load if not already loaded
        if (state.getModuleDetail(TemperaturePage.moduleId) == null &&
            !state.isLoadingModuleDetails) {
          context.read<HomeBloc>().add(
            LoadModuleDetail(moduleId: TemperaturePage.moduleId),
          );
        }

        final moduleDetail = state.getModuleDetail(TemperaturePage.moduleId);

        return Scaffold(
          body: Stack(
            children: [
              SafeArea(child: _buildBody(context, state, moduleDetail)),
              // Sticky bottom action bar
              if (moduleDetail != null)
                StickyBottomActionBar(
                  isVisible: _showActionBar,
                  moduleDetail: moduleDetail,
                  platformConfig:
                      _currentPlatformConfig ??
                      moduleDetail.platformConfigs.first,
                  onInterfacePressed:
                      () => context.push(
                        '${moduleDetail.route}${moduleDetail.interfaceRoute}',
                      ),
                  onDownloadPressed: () => _handleDownload(moduleDetail),
                ),
            ],
          ),
          floatingActionButton: AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(bottom: _showActionBar ? 80 : 0),
            child: PxChatBotFloatingButton(
              moduleKey: moduleDetail?.chatModuleKey ?? 'temperature',
            ),
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
                    LoadModuleDetail(moduleId: TemperaturePage.moduleId),
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
        controller: _scrollController,
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
              BuildMainContent(
                moduleDetail: moduleDetail,
                onPlatformChanged: (config) {
                  setState(() {
                    _currentPlatformConfig = config;
                  });
                },
              ),
            ]),
          ),
        ],
      );
    }

    // Fallback (should never reach here)
    return const Center(child: Text('No se pudo cargar el módulo'));
  }

  Future<void> _handleDownload(ModuleDetail moduleDetail) async {
    final shareFileUseCase = getIt<ShareFileUseCase>();
    final snackbarService = getIt<SnackbarService>();

    final platformConfig =
        _currentPlatformConfig ?? moduleDetail.platformConfigs.first;
    final inoFile = platformConfig.inoFile;

    final result = await shareFileUseCase(
      assetPath: inoFile.filePath,
      fileName: inoFile.fileName,
      text:
          'Código ${platformConfig.platform.displayName} para ${moduleDetail.title}',
      subject: 'Archivo INO - ${moduleDetail.title}',
    );

    result.fold(
      (failure) {
        String errorMessage;
        if (failure.message.contains('no encontrado')) {
          errorMessage = 'Error al compartir archivo: Archivo no encontrado';
        } else if (failure.message.contains('guardar')) {
          errorMessage =
              'Error al compartir archivo: No se pudo guardar el archivo';
        } else if (failure.message.contains('plataforma')) {
          errorMessage = 'Error al compartir archivo: Error de la plataforma';
        } else {
          errorMessage = 'Error al compartir archivo: Error desconocido';
        }

        snackbarService.show(
          message: errorMessage,
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          style: SnackbarStyle.withClose,
        );
      },
      (_) {
        // Success - no confirmation needed
      },
    );
  }
}
