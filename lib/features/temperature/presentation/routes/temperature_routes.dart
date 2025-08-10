import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/entities/instruction.dart';
import '../../../../core/entities/material.dart';
import '../../../../di/service_locator.dart';
import '../bloc/temperature_bloc.dart';
import '../pages/instruction_detail_page.dart';
import '../pages/material_details_page.dart';
import '../pages/temperature_page.dart';

final temperatureRoutes = [
  GoRoute(
    path: TemperaturePage.routeName,
    name: TemperaturePage.routeName,
    builder:
        (context, state) => BlocProvider(
          create: (_) => getIt<TemperatureBloc>(),
          child: const TemperaturePage(),
        ),
    routes: [
      GoRoute(
        path: TemperatureInstructionDetailsPage.routeName,
        name: TemperatureInstructionDetailsPage.routeName,
        builder: (context, state) {
          final instructions = state.extra as List<Instruction>;
          return TemperatureInstructionDetailsPage(intructions: instructions);
        },
        // ^ builder ⇒ usa MaterialPage ⇒ animación por defecto (fade/slide)
      ),
      GoRoute(
        path: TemperatureMaterialDetailsPage.routeName,
        name: TemperatureMaterialDetailsPage.routeName,
        builder: (context, state) {
          final materials = state.extra as List<MaterialItem>;
          return TemperatureMaterialDetailsPage(materials: materials);
        },
        // ^ builder ⇒ usa MaterialPage ⇒ animación por defecto (fade/slide)
      ),
    ],
  ),
];
