import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../di/service_locator.dart';
import '../bloc/gamepad_bloc.dart';
import '../pages/gamepad_page.dart';
import '../widgets/gamepad_interface_page.dart';

final gamepadRoutes = [
  GoRoute(
    path: GamepadPage.routeName,
    name: GamepadPage.routeName,
    builder:
        (context, state) => BlocProvider(
          create: (_) => getIt<GamepadBloc>(),
          child: GamepadPage(),
        ),
    routes: [
      GoRoute(
        path: GamepadInterfacePage.routeName,
        name: GamepadInterfacePage.routeName,
        pageBuilder: (context, state) {
          return NoTransitionPage(
            child: BlocProvider<GamepadBloc>(
              create: (_) => getIt<GamepadBloc>(),
              child: const GamepadInterfacePage(),
            ),
          );
        },
      ),
      // GoRoute(
      //   path: InstructionDetailsPage.routeName,
      //   name: InstructionDetailsPage.routeName,
      //   builder: (context, state) {
      //     final instructions = state.extra as List<InstructionItem>;
      //     return InstructionDetailsPage(instructions: instructions);
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
