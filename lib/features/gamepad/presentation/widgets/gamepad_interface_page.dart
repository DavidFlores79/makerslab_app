// ABOUTME: Gamepad interface page with joystick and action buttons for Bluetooth remote control.
// ABOUTME: Manages landscape orientation, immersive mode, and sub-view routing by BLoC state.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:simple_joystick/simple_joystick.dart';
import 'package:simple_joystick/stick_drag_callback.dart';
import 'package:makerslab_app/core/ui/bluetooth_dialogs.dart';
import 'package:makerslab_app/core/ui/snackbar_service.dart';
import 'package:makerslab_app/di/service_locator.dart';
import 'package:makerslab_app/shared/widgets/index.dart';
import 'package:makerslab_app/theme/app_color.dart';

import '../../../../core/presentation/bloc/bluetooth/bluetooth_bloc.dart';
import '../../../../core/presentation/bloc/bluetooth/bluetooth_event.dart';
import '../../../../core/presentation/bloc/bluetooth/bluetooth_state.dart';
import '../../../../core/presentation/bloc/heartbeat/heartbeat_bloc.dart';
import '../../../../core/presentation/bloc/heartbeat/heartbeat_state.dart';
import '../../../gamepad/presentation/bloc/gamepad_bloc.dart';

// ---------------------------------------------------------------------------
// Screen & system UI helpers
// ---------------------------------------------------------------------------

/// Forces landscape or portrait device orientation.
void _setPreferredOrientations({required bool landscape}) {
  SystemChrome.setPreferredOrientations([
    if (landscape) ...[
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ] else
      DeviceOrientation.portraitUp,
  ]);
}

/// Switches between immersive (full-screen, no system bars) and normal UI mode.
void _setEnabledSystemUIMode({required bool immersive}) {
  if (immersive) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  } else {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  }
}

// ---------------------------------------------------------------------------
// Page shell
// ---------------------------------------------------------------------------

/// Entry point for the gamepad feature.
///
/// Provides the [GamepadBloc] and listens to [BluetoothBloc] connection events.
/// Shows an [AppBar] only when the device is not yet connected (landscape
/// immersive mode hides it while playing).
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
    final bool isConnected = context.select(
      (BluetoothBloc b) => b.state is BluetoothConnected,
    );

    return BlocProvider(
      create: (_) => getIt<GamepadBloc>(),
      child: BlocListener<BluetoothBloc, BluetoothState>(
        listener: _onBluetoothStateChanged,
        child: Scaffold(
          appBar: isConnected ? null : _buildAppBar(context),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: BlocBuilder<GamepadBloc, GamepadState>(
                builder: _buildBody,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Reacts to Bluetooth connection/disconnection events at the page level.
  void _onBluetoothStateChanged(BuildContext context, BluetoothState state) {
    if (state is BluetoothConnected) {
      SnackbarService().show(
        message: 'Conectado a ${state.device.name ?? state.device.address}',
      );
    } else if (state is BluetoothError) {
      SnackbarService().show(message: 'Error de conexión: ${state.message}');
    } else if (state is BluetoothDisconnected) {
      _setEnabledSystemUIMode(immersive: false);
      _setPreferredOrientations(landscape: false);
    }
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Control Remoto'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _handleBackPress(context),
      ),
      actions: [_BluetoothStatusButton()],
    );
  }

  /// Navigates back, or prompts for disconnection if a device is connected.
  void _handleBackPress(BuildContext context) {
    final btState = context.read<BluetoothBloc>().state;
    if (btState is BluetoothConnected) {
      BluetoothDialogs.showDisconnectDialog(context, popPageAfter: true);
    } else {
      context.pop();
    }
  }

  /// Selects the correct sub-view based on [GamepadBloc] and [BluetoothBloc] state.
  Widget _buildBody(BuildContext context, GamepadState state) {
    if (state is GamepadLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (context.select((BluetoothBloc b) => b.state is BluetoothConnecting)) {
      return const ConnectingView();
    }

    if (state is GamepadConnected) {
      _setEnabledSystemUIMode(immersive: true);
      return _GamepadConnectedView();
    }

    if (state is GamepadDisconnected) {
      _setEnabledSystemUIMode(immersive: false);
      context.read<BluetoothBloc>().add(BluetoothDisconnectRequested());
      return const DisconnectedView();
    }

    if (state is GamepadError) {
      return ErrorView(
        message: state.message,
        onRetry:
            () => BluetoothDialogs.showDeviceSelectionModal(
              context,
              instructionalText: 'Selecciona tu ESP32 para control remoto.',
            ),
      );
    }

    return const InitialView();
  }
}

// ---------------------------------------------------------------------------
// Shared Bluetooth status button (AppBar + in-game overlay)
// ---------------------------------------------------------------------------

/// Icon button that reflects Bluetooth connection status and toggles connect/disconnect.
///
/// Used both in the [AppBar] (disconnected state) and as an overlay
/// button inside [_GamepadConnectedView] (connected/immersive state).
class _BluetoothStatusButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<BluetoothBloc, BluetoothState, bool>(
      selector: (state) => state is BluetoothConnected,
      builder: (context, isConnected) {
        return IconButton(
          tooltip: isConnected ? 'Desconectar' : 'Buscar dispositivo',
          icon: Icon(
            Icons.bluetooth,
            color: isConnected ? AppColors.lightGreen : AppColors.redAccent,
          ),
          onPressed:
              () =>
                  isConnected
                      ? BluetoothDialogs.showDisconnectDialog(context)
                      : BluetoothDialogs.showDeviceSelectionModal(
                        context,
                        instructionalText:
                            'Selecciona tu ESP32 para control remoto.',
                      ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Connected view (landscape + immersive)
// ---------------------------------------------------------------------------

/// Full-screen gamepad layout shown when a Bluetooth device is connected.
///
/// Forces landscape orientation on mount and waits for the rotation to settle
/// before drawing the controls, avoiding a cramped layout during the transition.
class _GamepadConnectedView extends StatefulWidget {
  @override
  State<_GamepadConnectedView> createState() => _GamepadConnectedViewState();
}

class _GamepadConnectedViewState extends State<_GamepadConnectedView> {
  // --- Orientation readiness ---
  bool _isLandscapeReady = false;
  Timer? _orientationCheckTimer;

  // --- Slider values (persisted across bottom sheet opens) ---
  final List<double> _sliderValues = [0.0, 0.0, 0.0];

  // --- Joystick command throttling ---
  Timer? _joystickReleaseTimer;
  Timer? _commandRepeatTimer;
  String _lastCommand = 'S00';
  DateTime? _lastJoystickUpdate;

  static const Duration _pollInterval = Duration(milliseconds: 50);
  static const Duration _orientationTimeout = Duration(milliseconds: 1000);

  @override
  void initState() {
    super.initState();
    _setPreferredOrientations(landscape: true);
    _waitForLandscape();
  }

  @override
  void dispose() {
    _setPreferredOrientations(landscape: false);
    _orientationCheckTimer?.cancel();
    _joystickReleaseTimer?.cancel();
    _commandRepeatTimer?.cancel();
    super.dispose();
  }

  // --- Orientation ---

  /// Polls until the device is in landscape (or times out), then shows the UI.
  void _waitForLandscape() {
    final start = DateTime.now();
    _orientationCheckTimer = Timer.periodic(_pollInterval, (timer) {
      if (!mounted) return;

      final orientation = MediaQuery.of(context).orientation;
      final elapsed = DateTime.now().difference(start);

      if (orientation == Orientation.landscape ||
          elapsed >= _orientationTimeout) {
        // Timeout covers rare cases where rotation fails or is too slow.
        setState(() => _isLandscapeReady = true);
        timer.cancel();
        _orientationCheckTimer = null;
      }
    });
  }

  // --- Joystick direction mapping ---

  /// Converts a joystick [alignment] offset to a directional command string.
  ///
  /// Returns 'S00' (stop) when the stick is near center, or one of:
  /// 'F01' (forward), 'B01' (backward), 'L01' (left), 'R01' (right).
  String _directionFromAlignment(Offset alignment) {
    final dx = alignment.dx;
    final dy = -alignment.dy; // invert Y so up = positive

    final magnitude = sqrt(dx * dx + dy * dy);
    // Lowered threshold (0.10) for more responsive control vs default 0.20.
    const double threshold = 0.10;
    if (magnitude < threshold) return 'S00';

    final angle = atan2(dy, dx) * 180 / pi;

    if (angle >= -45 && angle < 45) return 'R01';
    if (angle >= 45 && angle < 135) return 'F01';
    if (angle >= -135 && angle < -45) return 'B01';
    return 'L01';
  }

  // --- Joystick event handling ---

  /// Handles each joystick position update.
  ///
  /// - Sends the command immediately when the direction changes.
  /// - Starts a 150 ms repeat timer to keep sending while the stick is held.
  /// - Starts a 500 ms release-detection timer to send 'S00' if updates stop.
  void _onJoystickMoved(StickDragDetails details, GamepadBloc bloc) {
    final cmd = _directionFromAlignment(
      Offset(details.alignment.x, details.alignment.y),
    );

    _lastJoystickUpdate = DateTime.now();

    // A new update resets both timers.
    _joystickReleaseTimer?.cancel();
    _joystickReleaseTimer = null;
    _commandRepeatTimer?.cancel();
    _commandRepeatTimer = null;

    if (cmd != _lastCommand) {
      debugPrint('📤 Sending command: $cmd (previous: $_lastCommand)');
      bloc.add(GamepadDirectionChanged(command: cmd));
      setState(() => _lastCommand = cmd);
    }

    // If the joystick returned to center, nothing more to do.
    if (cmd == 'S00') return;

    // Keep resending the last command every 150 ms while the stick is held.
    _commandRepeatTimer = Timer.periodic(const Duration(milliseconds: 150), (
      _,
    ) {
      if (_lastCommand != 'S00') {
        _lastJoystickUpdate = DateTime.now(); // keep timestamp fresh
        debugPrint('🔄 Repeating command: $_lastCommand');
        bloc.add(GamepadDirectionChanged(command: _lastCommand));
      }
    });

    // Safety net: if no joystick events arrive for 500 ms, assume it was released.
    _joystickReleaseTimer = Timer(const Duration(milliseconds: 500), () {
      final timeSinceUpdate =
          DateTime.now().difference(_lastJoystickUpdate!).inMilliseconds;
      if (_lastCommand != 'S00' && timeSinceUpdate >= 400) {
        debugPrint('📤 Joystick timeout — sending S00');
        _commandRepeatTimer?.cancel();
        _commandRepeatTimer = null;
        bloc.add(GamepadDirectionChanged(command: 'S00'));
        setState(() => _lastCommand = 'S00');
      }
    });
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    if (!_isLandscapeReady) {
      return const Center(
        child: SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final bloc = context.read<GamepadBloc>();
    final joystickAreaSize = min(size.height, size.width) * 0.55;
    final joystickStickSize = joystickAreaSize * 0.3;

    return Stack(
      children: [
        // Main split layout: joystick left, buttons right.
        Row(
          children: [
            Expanded(
              child: _buildJoystickSection(
                bloc,
                joystickAreaSize,
                joystickStickSize,
              ),
            ),
            Expanded(child: _buildActionButtonsSection(size)),
          ],
        ),

        // Overlay: slider toggle button (top-center).
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: Center(
            child: IconButton(
              tooltip: 'Mostrar sliders',
              icon: const Icon(Icons.tune, color: Colors.white54, size: 20),
              onPressed: () => _showSliderBottomSheet(context),
            ),
          ),
        ),

        // Overlay: back button (top-left).
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

        // Overlay: Bluetooth status button (top-right).
        Positioned(top: 12, right: 12, child: _BluetoothStatusButton()),

        // Overlay: heartbeat pulse indicator (bottom-left, discrete).
        const Positioned(bottom: 16, left: 16, child: _HeartbeatIndicator()),

        // Overlay: L / R shoulder buttons (bottom-center).
        Positioned(
          bottom: 16,
          left: size.width * 0.5 - 70,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SideControlButton(label: 'L', code: 'L02'),
              SizedBox(width: 40),
              _SideControlButton(label: 'R', code: 'R02'),
            ],
          ),
        ),
      ],
    );
  }

  /// Opens a bottom sheet with three horizontal sliders (SL1, SL2, SL3).
  void _showSliderBottomSheet(BuildContext context) {
    final bloc = context.read<GamepadBloc>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => _SliderSheet(
            initialValues: List.of(_sliderValues),
            onChanged: (index, value) => _sliderValues[index] = value,
            onChangeEnd:
                (index, value) => bloc.add(
                  GamepadSliderChanged(
                    sliderId: index + 1,
                    value: value.round(),
                  ),
                ),
          ),
    );
  }

  /// Left half: joystick + last-command display.
  Widget _buildJoystickSection(
    GamepadBloc bloc,
    double areaSize,
    double stickSize,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        JoyStick(
          areaSize,
          stickSize,
          (details) => _onJoystickMoved(details, bloc),
          joyStickAreaColor: AppColors.primary.withAlpha(30),
          joyStickStickColor: AppColors.primary,
        ),
        const SizedBox(height: 12),
        const _CommandDisplay(),
      ],
    );
  }

  /// Right half: four action buttons arranged in a diamond (Y top, A bottom, X left, B right).
  Widget _buildActionButtonsSection(Size size) {
    final panelSize = min(380.0, size.width * 0.275);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: panelSize,
          height: panelSize,
          child: Stack(
            children: [
              _GamepadActionButton(
                color: AppColors.lightGreen,
                icon: Icons.change_history,
                code: 'Y00',
              ), // top    (triangle)
              _GamepadActionButton(
                color: AppColors.blue,
                icon: Icons.close,
                code: 'A00',
                alignment: Alignment.bottomCenter,
              ), // bottom (X)
              _GamepadActionButton(
                color: AppColors.purple,
                icon: Icons.stop_rounded,
                code: 'X00',
                alignment: Alignment.centerLeft,
              ), // left   (square)
              _GamepadActionButton(
                color: AppColors.redAccent,
                icon: Icons.radio_button_unchecked,
                code: 'B00',
                alignment: Alignment.centerRight,
              ), // right  (circle)
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Command display
// ---------------------------------------------------------------------------

/// Shows the last command sent to the device and the current BLoC state label.
class _CommandDisplay extends StatelessWidget {
  const _CommandDisplay();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GamepadBloc, GamepadState>(
      builder: (context, state) {
        final cmd = state is GamepadConnected ? state.lastSentCommand : 'S00';
        final isConnected = state is GamepadConnected;
        final stateLabel = state.runtimeType.toString().replaceAll(
          'Gamepad',
          '',
        );

        return Column(
          children: [
            const Text('TX', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: Text(
                cmd,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Estado: $stateLabel',
              style: TextStyle(
                fontSize: 12,
                color: isConnected ? AppColors.lightGreen : AppColors.redAccent,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Action button
// ---------------------------------------------------------------------------

/// Circular action button (Y / A / X / B) for the right side of the gamepad.
///
/// Size is proportional to the screen width and clamped to a sane range [44, 120].
/// When not connected, [alignment] is ignored and the button is centered.
class _GamepadActionButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String code;
  final Alignment alignment;

  const _GamepadActionButton({
    required this.color,
    required this.icon,
    required this.code,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GamepadBloc>();
    final size = MediaQuery.of(context).size;

    final bool isConnected = context.select(
      (BluetoothBloc b) => b.state is BluetoothConnected,
    );

    // Proportional diameter based on screen width, clamped to [44, 120].
    final double baseFactor = size.width < 600 ? 0.12 : 0.08;
    final double diameter = (size.width * baseFactor).clamp(44.0, 120.0);
    final double iconSize = diameter * 0.46;
    final double innerPadding = diameter * 0.12;

    return Align(
      alignment: isConnected ? alignment : Alignment.center,
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
            shadowColor: Colors.black.withValues(alpha: 0.25),
          ),
          child: Icon(icon, color: AppColors.white, size: iconSize),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Heartbeat indicator
// ---------------------------------------------------------------------------

/// Small animated heart in the bottom-left corner that pulses on each heartbeat.
///
/// Visibility is controlled by the [HeartbeatBloc] preference setting.
/// The pulse animation is triggered by [GamepadConnected.heartbeatBeat] toggling.
class _HeartbeatIndicator extends StatefulWidget {
  const _HeartbeatIndicator();

  @override
  State<_HeartbeatIndicator> createState() => _HeartbeatIndicatorState();
}

class _HeartbeatIndicatorState extends State<_HeartbeatIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.7), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.7, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<HeartbeatBloc>(),
      child: BlocSelector<HeartbeatBloc, HeartbeatState, bool>(
        selector: (state) => state is HeartbeatLoaded ? state.isEnabled : true,
        builder: (context, isEnabled) {
          if (!isEnabled) return const SizedBox.shrink();

          return BlocListener<GamepadBloc, GamepadState>(
            listenWhen:
                (prev, curr) =>
                    curr is GamepadConnected &&
                    prev is GamepadConnected &&
                    curr.heartbeatBeat != prev.heartbeatBeat,
            listener: (_, __) => _controller.forward(from: 0),
            child: ScaleTransition(
              scale: _scale,
              child: Icon(
                Icons.favorite,
                size: 16,
                color: Colors.redAccent.withValues(alpha: 0.7),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shoulder buttons (L / R)
// ---------------------------------------------------------------------------

/// Small labeled button for the L and R shoulder controls.
class _SideControlButton extends StatelessWidget {
  final String label;
  final String code;

  const _SideControlButton({required this.label, required this.code});

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

// ---------------------------------------------------------------------------
// Slider bottom sheet
// ---------------------------------------------------------------------------

/// Compact bottom sheet with three horizontal sliders (SL1, SL2, SL3).
///
/// Uses its own state so the slider thumbs update smoothly while dragging.
/// Calls [onChanged] on every tick (to keep parent values in sync) and
/// [onChangeEnd] when the user lifts a finger (to send the BLE command).
class _SliderSheet extends StatefulWidget {
  final List<double> initialValues;
  final void Function(int index, double value) onChanged;
  final void Function(int index, double value) onChangeEnd;

  const _SliderSheet({
    required this.initialValues,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  State<_SliderSheet> createState() => _SliderSheetState();
}

class _SliderSheetState extends State<_SliderSheet> {
  late final List<double> _values;

  @override
  void initState() {
    super.initState();
    _values = List.of(widget.initialValues);
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['SL1', 'SL2', 'SL3'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < 3; i++)
            Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    labels[i],
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _values[i],
                    min: 0,
                    max: 255,
                    divisions: 255,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.primary.withAlpha(60),
                    onChanged: (v) {
                      setState(() => _values[i] = v);
                      widget.onChanged(i, v);
                    },
                    onChangeEnd: (v) => widget.onChangeEnd(i, v),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${_values[i].round()}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
