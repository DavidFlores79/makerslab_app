import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../di/service_locator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../gamepad/presentation/bloc/gamepad_bloc.dart';
import '../../../gamepad/presentation/pages/gamepad_page.dart';
import '../../../light_control/presentation/pages/light_control_page.dart';
import '../../../light_control/presentation/bloc/light_control_bloc.dart';
import '../../../servo/presentation/pages/servo_page.dart';
import '../../../servo/presentation/bloc/servo_bloc.dart';
import '../../../temperature/presentation/routes/temperature_routes.dart';

final mainStaticRoutes = [
  GoRoute(
    path: GamepadPage.routeName,
    name: GamepadPage.routeName,
    builder:
        (context, state) => BlocProvider(
          create: (_) => getIt<GamepadBloc>(),
          child: GamepadPage(),
        ),
  ),
  ...temperatureRoutes,
  GoRoute(
    path: ServoPage.routeName,
    name: ServoPage.routeName,
    builder:
        (context, state) => BlocProvider(
          create: (_) => getIt<ServosBloc>(),
          child: ServoPage(),
        ),
  ),
  GoRoute(
    path: LightControlPage.routeName,
    name: LightControlPage.routeName,
    builder:
        (context, state) => BlocProvider(
          create: (_) => getIt<LightControlsBloc>(),
          child: LightControlPage(),
        ),
  ),

  //validate if there is a session open if not redirect to login
  GoRoute(
    path: ChatPage.routeName,
    name: ChatPage.routeName,
    builder: (context, state) {
      final isLoggedIn = context.read<AuthBloc>().state is Authenticated;

      if (!isLoggedIn) {
        return LoginPage();
      }

      return BlocProvider(
        create: (_) => getIt<ChatBloc>(),
        child: const ChatPage(),
      );
    },
  ),
];
