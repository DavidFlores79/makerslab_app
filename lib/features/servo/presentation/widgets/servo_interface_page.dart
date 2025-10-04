// lib/features/servo_control/presentation/pages/servo_control_interface_page.dart
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:makerslab_app/core/ui/bluetooth_dialogs.dart';
import 'package:makerslab_app/core/ui/snackbar_service.dart';
import 'package:makerslab_app/di/service_locator.dart';
import 'package:makerslab_app/shared/widgets/index.dart';
import 'package:makerslab_app/theme/app_color.dart';

import '../../../../core/presentation/bloc/bluetooth/bluetooth_bloc.dart';
import '../../../../core/presentation/bloc/bluetooth/bluetooth_event.dart';
import '../../../../core/presentation/bloc/bluetooth/bluetooth_state.dart';
import '../bloc/servo_bloc.dart';
import 'custom_servo_slider.dart';

class ServoInterfacePage extends StatefulWidget {
  static const String routeName = '/servo/interface';
  const ServoInterfacePage({super.key});

  @override
  State<ServoInterfacePage> createState() => _ServoInterfacePageState();
}

class _ServoInterfacePageState extends State<ServoInterfacePage> {
  final TextEditingController _textController = TextEditingController(
    text: '0',
  );
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _textFocusNode = FocusNode();

  double _currentAngle = 0.0;

  @override
  void initState() {
    KeepScreenOn.turnOn();
    _textFocusNode.addListener(() {
      if (_textFocusNode.hasFocus) {
        // selección al final para asegurar que se vea seleccionada
        _textController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _textController.text.length,
        );
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    KeepScreenOn.turnOff();
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  // helper para setear texto y dejar cursor al final
  void _setControllerTextSafely(String text) {
    _textController.text = text;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ServoBloc>(),
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
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Control de Servo'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                final bluetoothState = context.read<BluetoothBloc>().state;
                if (bluetoothState is BluetoothConnected) {
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
                    tooltip: isConnected ? 'Desconectar' : 'Buscar dispositivo',
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
                              'Selecciona tu ESP32 para controlar el servo.',
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: BlocBuilder<ServoBloc, ServoState>(
                builder: (context, state) {
                  if (state is ServoLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (context.select(
                    (BluetoothBloc b) => b.state is BluetoothConnecting,
                  )) {
                    return const ConnectingView();
                  }

                  if (state is ServoConnected) {
                    // Solo actualizar el controller.text si la posición real cambió
                    final displayedAngle = state.position ?? _currentAngle;
                    if (displayedAngle != _currentAngle) {
                      _currentAngle = displayedAngle;
                      _setControllerTextSafely(
                        displayedAngle.round().toString(),
                      );
                    }

                    return _ServoConnectedView(
                      focusNode: _textFocusNode,
                      angle: _currentAngle,
                      onSend: (double angle) {
                        // enviar evento al bloc
                        context.read<ServoBloc>().add(
                          ServoPositionRequested(angle: angle),
                        );

                        // feedback inmediato: actualizamos el estado local y el controller
                        setState(() {
                          _currentAngle = angle;
                          _setControllerTextSafely(angle.round().toString());
                        });

                        // quitar foco para cerrar teclado
                        FocusScope.of(context).unfocus();
                      },
                      onSliding: (double angle) {
                        // preview: notificar al bloc (opcional) y actualizar solo la UI localmente
                        context.read<ServoBloc>().add(
                          ServoPositionPreviewRequested(angle: angle),
                        );
                        setState(() => _currentAngle = angle);
                        // no forzamos la reasignación del controller aquí para no romper el input del usuario
                      },
                      textController: _textController,
                      formKey: _formKey,
                    );
                  }

                  if (state is ServoDisconnected) {
                    context.read<BluetoothBloc>().add(
                      BluetoothDisconnectRequested(),
                    );
                    return const DisconnectedView();
                  }

                  if (state is ServoError) {
                    return ErrorView(
                      message: state.message,
                      onRetry:
                          () => BluetoothDialogs.showDeviceSelectionModal(
                            context,
                            instructionalText:
                                'Selecciona tu ESP32 para controlar el servo.',
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

// ==============================
// WIDGETS DE LA VISTA CONECTADA
// ==============================
class _ServoConnectedView extends StatelessWidget {
  final double angle;
  final void Function(double angle) onSend;
  final void Function(double angle) onSliding;
  final TextEditingController textController;
  final GlobalKey<FormState>? formKey;
  final FocusNode? focusNode;

  const _ServoConnectedView({
    required this.angle,
    required this.onSend,
    required this.onSliding,
    required this.textController,
    this.formKey,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;
    final servoImageHeight = 200.0;

    //calculate servo image width based on height
    final servoImageWidth = servoImageHeight * 0.5;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Imagen del servo con cuerno rotatorio
            SizedBox(
              width: double.infinity,
              height: 250,
              child: Stack(
                children: [
                  // Motor base
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Image.asset(
                        'assets/images/modules/servo_motor.png',
                        height: servoImageHeight,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // Horn rotatorio
                  Positioned(
                    top: servoImageHeight * 0.2,
                    left: (size.width * 0.5) - (servoImageWidth * 0.5),
                    child: Transform.rotate(
                      //rotate the other way to match the servo rotation
                      angle: -pi * angle / 180,
                      alignment: Alignment.centerLeft,
                      origin: const Offset(25, 0),
                      child: Image.asset(
                        'assets/images/modules/servo_horn.png',
                        height: servoImageHeight * 0.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Indicador de angulo
            Text(
              'Ángulo: ${angle.round()}°',
              style: theme.headlineMedium?.copyWith(
                color: AppColors.lightGreen,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Input de posición
            Container(
              width: size.width * 0.6,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Form(
                key: formKey,
                child: PXCustomTextField(
                  focusNode: focusNode,
                  controller: textController,
                  labelText: 'Posición (0 a 180)',
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  // Si tu PXCustomTextField acepta onTap/onChanged puedes agregarlos aquí
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese un valor';
                    }
                    final int? v = int.tryParse(value);
                    if (v == null) return 'Valor inválido';
                    if (v < 0 || v > 180) {
                      return 'El valor debe estar entre 0 y 180.';
                    }
                    return null;
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Boton enviar
            MainAppButton(
              label: 'Enviar Posición',
              onPressed: () {
                final parsed = double.tryParse(textController.text) ?? angle;
                final clamped = parsed.clamp(0, 180);
                onSend(double.tryParse(clamped.toString()) ?? angle);
              },
            ),

            const SizedBox(height: 60),

            // Slider
            SizedBox(
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Gradient track custom (fondo)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: CustomPaint(
                      painter: _GradientTrackPainter(),
                      size: Size(double.infinity, 48),
                    ),
                  ),

                  // Slider real encima (usa ancho máximo)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: CustomServoSlider(
                      angle: angle,
                      onChanged: (v) {
                        onSliding(v);
                      },
                      onChangeEnd: (v) {
                        onSend(v);
                      },
                    ),
                  ),
                ],
              ),
            ),

            //Explain how slider works
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Usa el slider para ajustar la posición del servo. Al mover el slider, se enviará la posición al dispositivo.',
                textAlign: TextAlign.center,
                style: theme.bodyMedium?.copyWith(color: AppColors.gray600),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _GradientTrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      0,
      size.height * 0.35,
      size.width,
      size.height * 0.30,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    final gradient = LinearGradient(
      colors: [AppColors.gray300, AppColors.gray200],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final paint =
        Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, paint);

    // Capa superior con brillo suave (sutil)
    final gloss =
        Paint()
          ..shader = LinearGradient(
            colors: [AppColors.whiteAlpha20, AppColors.whiteAlpha10],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(rect)
          ..blendMode = ui.BlendMode.srcOver;

    final topRect = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width,
      rect.height * 0.5,
    );
    final topRRect = RRect.fromRectAndCorners(
      topRect,
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
    );
    canvas.drawRRect(topRRect, gloss);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
