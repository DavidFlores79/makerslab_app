import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../di/service_locator.dart';
import '../bloc/servo_bloc.dart';
import '../pages/servo_page.dart';
import '../widgets/servo_interface_page.dart';

final servoRoutes = [
  GoRoute(
    path: ServoPage.routeName,
    name: ServoPage.routeName,
    builder:
        (context, state) =>
            BlocProvider(create: (_) => getIt<ServoBloc>(), child: ServoPage()),
    routes: [
      GoRoute(
        path: ServoInterfacePage.routeName,
        name: ServoInterfacePage.routeName,
        pageBuilder: (context, state) {
          return NoTransitionPage(
            child: BlocProvider<ServoBloc>(
              create: (_) => getIt<ServoBloc>(),
              child: const ServoInterfacePage(),
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
