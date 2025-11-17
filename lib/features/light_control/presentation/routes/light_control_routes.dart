import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// import 'package:makerslab_app/features/home/domain/entities/instruction_item.dart';
// import 'package:makerslab_app/features/home/domain/entities/material_item.dart';
import '../../../../di/service_locator.dart';
import '../../../../features/home/presentation/bloc/home_bloc.dart';
import '../bloc/light_control_bloc.dart';
import '../pages/light_control_page.dart';
import '../widgets/light_control_interface_page.dart';

final lightControlRoutes = [
  GoRoute(
    path: LightControlPage.routeName,
    name: LightControlPage.routeName,
    builder:
        (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider<HomeBloc>(create: (_) => getIt<HomeBloc>()),
            BlocProvider<LightControlBloc>(
              create: (_) => getIt<LightControlBloc>(),
            ),
          ],
          child: LightControlPage(),
        ),
    routes: [
      GoRoute(
        path: 'interface',
        name: LightControlInterfacePage.routeName,
        pageBuilder: (context, state) {
          return NoTransitionPage(
            child: BlocProvider<LightControlBloc>(
              create: (_) => getIt<LightControlBloc>(),
              child: const LightControlInterfacePage(),
            ),
          );
        },
      ),
      // GoRoute(
      //   path: LightControlInstructionDetailsPage.routeName,
      //   name: LightControlInstructionDetailsPage.routeName,
      //   builder: (context, state) {
      //     final instructions = state.extra as List<InstructionItem>;
      //     return LightControlInstructionDetailsPage(instructions: instructions);
      //   },
      //   // ^ builder ⇒ usa MaterialPage ⇒ animación por defecto (fade/slide)
      // ),
      // GoRoute(
      //   path: LightControlMaterialDetailsPage.routeName,
      //   name: LightControlMaterialDetailsPage.routeName,
      //   builder: (context, state) {
      //     final materials = state.extra as List<MaterialItem>;
      //     return LightControlMaterialDetailsPage(materials: materials);
      //   },
      //   // ^ builder ⇒ usa MaterialPage ⇒ animación por defecto (fade/slide)
      // ),
    ],
  ),
];
