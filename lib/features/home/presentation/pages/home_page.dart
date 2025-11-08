import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:makerslab_app/core/ui/snackbar_service.dart';

import '../../../../shared/widgets/index.dart';
import '../../../../theme/app_color.dart';
import '../../../../utils/color_utils.dart';
import '../../../../utils/util_image.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
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

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(LoadHomeData());
  }

  @override
  Widget build(BuildContext context) {
    bool showSnackbar = true;
    return Scaffold(
      appBar: PxMainAppBar(),
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, authState) {
            if (authState is SessionClosed) {
              if (!context.mounted) return;
              //reload menu items
              context.read<HomeBloc>().add(LoadHomeData());
              showSnackbar = false;
            }
            if (authState is Unauthenticated) {
              if (!context.mounted) return;
              if (!showSnackbar) return;
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
                  child: Text('Error: ${state.error ?? 'Algo salió mal'}'),
                );
              }
              if (state.status == HomeStatus.success) {
                context.read<AuthBloc>().add(CheckAuthStatus());
                final List<MainMenuItemModel> menu = state.mainMenuItems ?? [];

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
                              final bgColor = colorFromHex(
                                m.colorHex ?? '#000000',
                              );

                              return Card(
                                color: AppColors.gray300,
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
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
                                        Center(child: UtilImage.buildIcon(m)),
                                        const SizedBox(height: 20),
                                        Text(
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          menu[index].title ?? '',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.black3,
                                          ),
                                        ),
                                      ],
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
  }
}
