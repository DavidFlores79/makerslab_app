import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:makerslab_app/core/ui/snackbar_service.dart';

import '../../../../shared/widgets/index.dart';
import '../../../../theme/app_color.dart';
import '../../../../utils/util_image.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../data/models/main_menu_item_model.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

class HomePage extends StatefulWidget {
  static const String routeName = "/home";
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool _hasShownSnackbar = false;
  DateTime? _lastResumeTime;

  @override
  void initState() {
    super.initState();
    debugPrint('>>> HomePage initState');

    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    context.read<HomeBloc>().add(LoadHomeData());

    // Check auth state after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      debugPrint('>>> HomePage - Current auth state after build: $authState');

      // Manually trigger snackbar if already unauthenticated
      if (authState is Unauthenticated && !_hasShownSnackbar) {
        debugPrint('>>> Showing snackbar from initState callback');
        _hasShownSnackbar = true;
        SnackbarService().show(
          duration: const Duration(seconds: 10),
          style: SnackbarStyle.withAction,
          message: 'Si inicias sesión, puedes obtener más módulos',
          actionLabel: 'Iniciar sesión',
          onAction: () async {
            final result = await context.push(LoginPage.routeName);
            if (result == true) {
              context.read<HomeBloc>().add(LoadHomeData());
            }
          },
        );
      }
    });
  }

  @override
  void dispose() {
    // CRITICAL: Remove lifecycle observer to prevent memory leaks
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    debugPrint('>>> HomePage lifecycle state changed: $state');

    if (state == AppLifecycleState.resumed) {
      _handleAppResume();
    }
  }

  /// Handles app resume with debouncing to prevent excessive reloads
  void _handleAppResume() {
    final now = DateTime.now();

    // Debounce: Only reload if more than 2 seconds since last resume
    if (_lastResumeTime != null) {
      final difference = now.difference(_lastResumeTime!);
      if (difference.inSeconds < 2) {
        debugPrint('>>> HomePage resume debounced (${difference.inSeconds}s since last resume)');
        return;
      }
    }

    _lastResumeTime = now;
    debugPrint('>>> HomePage reloading data after app resume');

    // Only reload if widget is still mounted
    if (mounted && context.mounted) {
      context.read<HomeBloc>().add(LoadHomeData());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final String? userName =
            authState is Authenticated
                ? (authState.user.name ?? authState.user.phone)
                : null;
        final String? userImage =
            authState is Authenticated ? authState.user.image : null;

        return Scaffold(
          appBar: PxMainAppBar(userName: userName, userImage: userImage),
          body: SafeArea(
            child: BlocListener<AuthBloc, AuthState>(
              listener: (context, authState) {
                debugPrint('>>> HomePage BlocListener - authState: $authState');

                if (authState is Authenticated) {
                  // Reset flag when user authenticates
                  debugPrint('>>> Authenticated - resetting snackbar flag');
                  _hasShownSnackbar = false;
                }

                if (authState is SessionClosed) {
                  if (!context.mounted) return;
                  debugPrint('>>> SessionClosed - reloading home data');
                  //reload menu items
                  context.read<HomeBloc>().add(LoadHomeData());
                }

                // Show snackbar once when unauthenticated
                if (authState is Unauthenticated && !_hasShownSnackbar) {
                  if (!context.mounted) return;
                  debugPrint('>>> Showing unauthenticated snackbar');
                  _hasShownSnackbar = true;
                  SnackbarService().show(
                    duration: const Duration(seconds: 10),
                    style: SnackbarStyle.withAction,
                    message: 'Si inicias sesión, puedes obtener más módulos',
                    actionLabel: 'Iniciar sesión',
                    onAction: () async {
                      final result = await context.push(LoginPage.routeName);
                      if (result == true) {
                        context.read<HomeBloc>().add(LoadHomeData());
                      }
                    },
                  );
                }
              },
              child: BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  if (state.status == HomeStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.status == HomeStatus.failure) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No se pudo cargar el menú',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.error ?? 'Algo salió mal. Por favor intenta de nuevo.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                              onPressed: () {
                                context.read<HomeBloc>().add(LoadHomeData());
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (state.status == HomeStatus.success) {
                    final List<MainMenuItemModel> menu =
                        state.mainMenuItems ?? [];

                    return Scrollbar(
                      thickness: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 20,
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                itemCount: menu.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      childAspectRatio: 1,
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 10.0,
                                      mainAxisSpacing: 10.0,
                                    ),
                                itemBuilder: (BuildContext context, int index) {
                                  final m = menu[index];

                                  final theme = Theme.of(context);
                                  final isDarkMode =
                                      theme.brightness == Brightness.dark;

                                  // RepaintBoundary improves performance by isolating each card's paint operations
                                  return RepaintBoundary(
                                    child: Card(
                                      color:
                                          isDarkMode
                                              ? theme
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                              : AppColors.gray300,
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.0),
                                        side: BorderSide(
                                          color:
                                              isDarkMode
                                                  ? theme.colorScheme.outline
                                                  : AppColors.gray500,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: InkWell(
                                        onTap:
                                            () => context.push(
                                              menu[index].route ?? '/',
                                            ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: <Widget>[
                                              Center(
                                                child: UtilImage.buildIcon(m),
                                              ),
                                              const SizedBox(height: 20),
                                              Text(
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                menu[index].title ?? '',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      theme.colorScheme.onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox(); // estado inicial
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
