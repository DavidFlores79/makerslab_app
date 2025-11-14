// lib/features/gamepad/presentation/pages/gamepad_interface_page.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:simple_joystick/simple_joystick.dart';
import 'package:makerslab_app/core/ui/bluetooth_dialogs.dart';
import 'package:makerslab_app/core/ui/snackbar_service.dart';
import 'package:makerslab_app/di/service_locator.dart';
import 'package:makerslab_app/shared/widgets/index.dart';
import 'package:makerslab_app/theme/app_color.dart';

import '../../../../core/presentation/bloc/bluetooth/bluetooth_bloc.dart';
import '../../../../core/presentation/bloc/bluetooth/bluetooth_event.dart';
import '../../../../core/presentation/bloc/bluetooth/bluetooth_state.dart';
import '../../../gamepad/presentation/bloc/gamepad_bloc.dart';

_setPreferredOrientations({required bool landscape}) {
  SystemChrome.setPreferredOrientations([
    if (landscape) ...[
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ] else
      DeviceOrientation.portraitUp,
  ]);
}

_setEnabledSystemUIMode({required bool immersive}) {
  if (immersive) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  } else {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  }
}

class GamepadInterfacePage extends StatefulWidget {
  static const String routeName = '/gamepad/interface';
  const GamepadInterfacePage({super.key});

  @override
  State<GamepadInterfacePage> createState() => _GamepadInterfacePageState();
}

class _GamepadInterfacePageState extends State<GamepadInterfacePage> {
  @override
  void initState() {
    KeepScreenOn.turnOn();
    super.initState();
  }

  @override
  void dispose() {
    KeepScreenOn.turnOff();
    _setPreferredOrientations(landscape: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // show appbar only if not connected
    final bool isConnected = context.select(
      (BluetoothBloc b) => b.state is BluetoothConnected,
    );
    return BlocProvider(
      create: (_) => getIt<GamepadBloc>(),
      child: BlocListener<BluetoothBloc, BluetoothState>(
        listener: (context, state) {
          if (state is BluetoothConnected) {
            SnackbarService().show(
              message:
                  'Conectado a ${state.device.name ?? state.device.address}',
            );
          } else if (state is BluetoothError) {
            SnackbarService().show(
              message: 'Error de conexión: ${state.message}',
            );
          } else if (state is BluetoothDisconnected) {
            _setEnabledSystemUIMode(immersive: false);
            _setPreferredOrientations(landscape: false);
          }
        },
        // show appbar only if not connected
        child: Scaffold(
          appBar:
              !isConnected
                  ? AppBar(
                    title: const Text('Control Remoto'),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        final btState = context.read<BluetoothBloc>().state;
                        if (btState is BluetoothConnected) {
                          BluetoothDialogs.showDisconnectDialog(
                            context,
                            popPageAfter: true,
                          );
                        } else {
                          context.pop();
                        }
                      },
                    ),
                    actions: [
                      BlocSelector<BluetoothBloc, BluetoothState, bool>(
                        selector: (state) => state is BluetoothConnected,
                        builder: (context, isConnected) {
                          return IconButton(
                            tooltip:
                                isConnected
                                    ? 'Desconectar'
                                    : 'Buscar dispositivo',
                            icon: Icon(
                              Icons.bluetooth,
                              color:
                                  isConnected
                                      ? AppColors.lightGreen
                                      : AppColors.redAccent,
                            ),
                            onPressed: () {
                              if (isConnected) {
                                BluetoothDialogs.showDisconnectDialog(context);
                              } else {
                                BluetoothDialogs.showDeviceSelectionModal(
                                  context,
                                  instructionalText:
                                      'Selecciona tu ESP32 para control remoto.',
                                );
                              }
                            },
                          );
                        },
                      ),
                    ],
                  )
                  : null,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: BlocBuilder<GamepadBloc, GamepadState>(
                builder: (context, state) {
                  if (state is GamepadLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (context.select(
                    (BluetoothBloc b) => b.state is BluetoothConnecting,
                  )) {
                    return const ConnectingView();
                  }

                  if (state is GamepadConnected) {
                    //full screen gamepad view
                    _setEnabledSystemUIMode(immersive: true);
                    return _GamepadConnectedView();
                  }

                  if (state is GamepadDisconnected) {
                    // We restore the system UI and orientation when disconnected
                    _setEnabledSystemUIMode(immersive: false);
                    context.read<BluetoothBloc>().add(
                      BluetoothDisconnectRequested(),
                    );
                    return const DisconnectedView();
                  }

                  if (state is GamepadError) {
                    return ErrorView(
                      message: state.message,
                      onRetry:
                          () => BluetoothDialogs.showDeviceSelectionModal(
                            context,
                            instructionalText:
                                'Selecciona tu ESP32 para control remoto.',
                          ),
                    );
                  }

                  return const InitialView();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// View that shows the gamepad controls when connected.
/// We force landscape orientation and hide system UI for immersion.
/// We wait for the orientation to be landscape before drawing the content
/// to avoid the buttons/stick looking cramped when changing orientation.
class _GamepadConnectedView extends StatefulWidget {
  @override
  State<_GamepadConnectedView> createState() => _GamepadConnectedViewState();
}

class _GamepadConnectedViewState extends State<_GamepadConnectedView> {
  bool _isLandscapeReady = false;
  Timer? _orientationCheckTimer;
  Timer? _joystickReleaseTimer;
  Timer? _commandRepeatTimer;
  String _lastCommand = 'S00';
  DateTime? _lastJoystickUpdate;
  final Duration _pollInterval = const Duration(milliseconds: 50);
  final Duration _timeout = const Duration(milliseconds: 1000);

  @override
  void initState() {
    super.initState();

    // We force landscape orientation when entering the connected view
    _setPreferredOrientations(landscape: true);

    // We start a periodic check of the orientation to ensure
    // that the system is already in landscape before rendering the full UI.
    final start = DateTime.now();
    _orientationCheckTimer = Timer.periodic(_pollInterval, (t) {
      // If the widget has already been unmounted, we exit
      if (!mounted) return;

      final orient = MediaQuery.of(context).orientation;
      final elapsed = DateTime.now().difference(start);

      if (orient == Orientation.landscape) {
        // We are already in landscape: show UI
        setState(() => _isLandscapeReady = true);
        _orientationCheckTimer?.cancel();
        _orientationCheckTimer = null;
      } else if (elapsed >= _timeout) {
        // Timeout: show UI anyway to avoid blocking permanently.
        // (This covers rare cases where rotation fails or is too slow.)
        setState(() => _isLandscapeReady = true);
        _orientationCheckTimer?.cancel();
        _orientationCheckTimer = null;
      }
      // If not, we keep waiting...
    });
  }

  @override
  void dispose() {
    // We restore exclusively portrait when leaving the connected view
    _setPreferredOrientations(landscape: false);

    _orientationCheckTimer?.cancel();
    _orientationCheckTimer = null;

    _joystickReleaseTimer?.cancel();
    _joystickReleaseTimer = null;

    _commandRepeatTimer?.cancel();
    _commandRepeatTimer = null;

    super.dispose();
  }

  String _directionFromAlignment(Offset alignment) {
    final dx = alignment.dx;
    final dy = -alignment.dy;
    final magnitude = sqrt(dx * dx + dy * dy);

    // Lowered threshold from 0.20 to 0.10 for more responsive control
    const double threshold = 0.10;
    if (magnitude < threshold) {
      debugPrint(
        'Joystick - STOP (magnitude: ${magnitude.toStringAsFixed(2)})',
      );
      return 'S00';
    }

    final angle = atan2(dy, dx) * 180 / pi;

    // Debug: Print actual values to verify mapping
    debugPrint(
      'Joystick - dx: ${dx.toStringAsFixed(2)}, dy: ${dy.toStringAsFixed(2)}, magnitude: ${magnitude.toStringAsFixed(2)}, angle: ${angle.toStringAsFixed(1)}°',
    );

    // Corrected mapping (rotated 90° to match Arduino orientation):
    // Right: angle ~0°   → B01 (Backward on Arduino)
    // Up: angle ~90°     → R01 (Right on Arduino)
    // Left: angle ~180°  → F01 (Forward on Arduino)
    // Down: angle ~-90°  → L01 (Left on Arduino)
    if (angle >= -45 && angle < 45) {
      return 'L01'; // Right on screen = Backward on Arduino
    } else if (angle >= 45 && angle < 135) {
      return 'F01'; // Up on screen = Right on Arduino
    } else if (angle >= -135 && angle < -45) {
      return 'B01'; // Down on screen = Left on Arduino
    } else {
      return 'R01'; // Left on screen = Forward on Arduino
    }
  }

  @override
  Widget build(BuildContext context) {
    // If the orientation is not ready yet, we show a centered placeholder
    if (!_isLandscapeReady) {
      return const Center(
        child: SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If it's ready, we render the normal gamepad UI (your implementation)
    final size = MediaQuery.of(context).size;
    final bloc = context.read<GamepadBloc>();
    final joystickAreaSize = min(size.height, size.width) * 0.55;
    final joystickStickSize = joystickAreaSize * 0.3;

    return Stack(
      children: [
        Positioned(
          top: 12,
          left: 12,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              final btState = context.read<BluetoothBloc>().state;
              if (btState is BluetoothConnected) {
                BluetoothDialogs.showDisconnectDialog(
                  context,
                  popPageAfter: true,
                );
              } else {
                context.pop();
              }
            },
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: BlocSelector<BluetoothBloc, BluetoothState, bool>(
            selector: (state) => state is BluetoothConnected,
            builder: (context, isConnected) {
              return IconButton(
                tooltip: isConnected ? 'Desconectar' : 'Buscar dispositivo',
                icon: Icon(
                  Icons.bluetooth,
                  color:
                      isConnected ? AppColors.lightGreen : AppColors.redAccent,
                ),
                onPressed: () {
                  if (isConnected) {
                    BluetoothDialogs.showDisconnectDialog(context);
                  } else {
                    BluetoothDialogs.showDeviceSelectionModal(
                      context,
                      instructionalText:
                          'Selecciona tu ESP32 para control remoto.',
                    );
                  }
                },
              );
            },
          ),
        ),
        Row(
          children: [
            // Joystick column
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  JoyStick(
                    // proportional size
                    joystickAreaSize,
                    joystickStickSize,
                    (details) {
                      final cmd = _directionFromAlignment(
                        Offset(details.alignment.x, details.alignment.y),
                      );

                      // Update timestamp - we got a joystick update
                      _lastJoystickUpdate = DateTime.now();

                      // Cancel any existing timers since we got an update
                      _joystickReleaseTimer?.cancel();
                      _joystickReleaseTimer = null;
                      _commandRepeatTimer?.cancel();
                      _commandRepeatTimer = null;

                      // Only send command if it changed to avoid flooding
                      if (cmd != _lastCommand) {
                        debugPrint(
                          '📤 Sending command: $cmd (previous: $_lastCommand)',
                        );
                        bloc.add(GamepadDirectionChanged(command: cmd));
                        setState(() {
                          _lastCommand = cmd;
                        });
                      }

                      // If the joystick moved back to center (S00), we're done
                      // No need to set a timer - the user released it
                      if (cmd == 'S00') {
                        return;
                      }

                      // For active movements (not S00), start a periodic timer
                      // to keep sending the command even if joystick stops updating
                      _commandRepeatTimer = Timer.periodic(
                        const Duration(milliseconds: 150),
                        (_) {
                          if (_lastCommand != 'S00') {
                            debugPrint('🔄 Repeating command: $_lastCommand');
                            _lastJoystickUpdate =
                                DateTime.now(); // Keep timestamp fresh to prevent timeout
                            bloc.add(
                              GamepadDirectionChanged(command: _lastCommand),
                            );
                          }
                        },
                      );

                      // Set a release timer as safety net
                      // If no joystick updates for 500ms, assume it was released
                      _joystickReleaseTimer = Timer(
                        const Duration(milliseconds: 500),
                        () {
                          if (_lastCommand != 'S00') {
                            final timeSinceUpdate =
                                DateTime.now()
                                    .difference(_lastJoystickUpdate!)
                                    .inMilliseconds;
                            if (timeSinceUpdate >= 400) {
                              debugPrint('📤 Joystick timeout - sending S00');
                              _commandRepeatTimer?.cancel();
                              _commandRepeatTimer = null;
                              bloc.add(GamepadDirectionChanged(command: 'S00'));
                              setState(() {
                                _lastCommand = 'S00';
                              });
                            }
                          }
                        },
                      );
                    },
                    joyStickAreaColor: AppColors.primary.withAlpha(30),
                    joyStickStickColor: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  BlocBuilder<GamepadBloc, GamepadState>(
                    builder: (context, state) {
                      return Column(
                        children: [
                          const Text(
                            'Joystick',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Comando: $_lastCommand',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Estado: ${state.runtimeType.toString().replaceAll('Gamepad', '')}',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  state is GamepadConnected
                                      ? AppColors.lightGreen
                                      : AppColors.redAccent,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Buttons column
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: min(380.0, size.width * 0.275),
                    height: min(380.0, size.width * 0.275),
                    child: Stack(
                      children: [
                        _GamepadActionButton(
                          color: AppColors.lightGreen,
                          icon: Icons.change_history, // triangle
                          code: 'Y00',
                        ),
                        _GamepadActionButton(
                          color: AppColors.blue,
                          icon: Icons.close, // x
                          code: 'A00',
                          alignment: Alignment.bottomCenter,
                        ),
                        _GamepadActionButton(
                          color: AppColors.purple,
                          icon: Icons.stop_rounded, // square substitute
                          code: 'X00',
                          alignment: Alignment.centerLeft,
                        ),
                        _GamepadActionButton(
                          color: AppColors.redAccent,
                          icon: Icons.radio_button_unchecked,
                          code: 'B00',
                          alignment: Alignment.centerRight,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Bottom side buttons centered
        Positioned(
          bottom: 16,
          left: size.width * 0.5 - 70,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SideControlButton(label: 'L', code: 'L02'),
              const SizedBox(width: 40),
              _SideControlButton(label: 'R', code: 'R02'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Main button of the gamepad (responsive; uses alignment only if there is a connection)
/// Main button of the gamepad (responsive and conditioning the alignment to the connection state)
class _GamepadActionButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String code;
  final Alignment alignment;

  const _GamepadActionButton({
    Key? key,
    required this.color,
    required this.icon,
    required this.code,
    this.alignment = Alignment.topCenter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GamepadBloc>();
    final size = MediaQuery.of(context).size;

    // We detect if there is a Bluetooth connection to decide whether to apply horizontal alignment
    final bool isConnected = context.select(
      (BluetoothBloc b) => b.state is BluetoothConnected,
    );

    // Proportional size: a percentage of the screen width, with limits.
    // Adjust the factors (0.10 / 0.07) if you want larger/smaller buttons.
    final double baseFactor = (size.width < 600) ? 0.12 : 0.08;
    double diameter = size.width * baseFactor;

    // Clamp to a nice range (e.g.: 44..120)
    diameter = diameter.clamp(44.0, 120.0);

    final double iconSize = diameter * 0.46;
    final double innerPadding = diameter * 0.12;

    // If not connected, we center the button; if connected we use the passed alignment.
    final Alignment effectiveAlignment =
        isConnected ? alignment : Alignment.center;

    return Align(
      alignment: effectiveAlignment,
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: ElevatedButton(
          onPressed: () => bloc.add(GamepadButtonPressed(code: code)),
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: EdgeInsets.all(innerPadding),
            backgroundColor: color,
            elevation: 6,
            // Ensures that the shadow and border look good on small sizes
            shadowColor: Colors.black.withOpacity(0.25),
          ),
          child: Icon(icon, color: AppColors.white, size: iconSize),
        ),
      ),
    );
  }
}

/// Botones L / R
class _SideControlButton extends StatelessWidget {
  final String label;
  final String code;
  const _SideControlButton({Key? key, required this.label, required this.code})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GamepadBloc>();
    return ElevatedButton(
      onPressed: () => bloc.add(GamepadButtonPressed(code: code)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}
