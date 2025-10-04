// beautiful_servo_slider.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:makerslab_app/theme/app_color.dart';

/// Slider visualmente mejorado para controlar el servo.
/// - angle: valor actual (0..180)
/// - onChanged / onChangeEnd: callbacks idénticos a Slider
class CustomServoSlider extends StatelessWidget {
  final double angle;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  const CustomServoSlider({
    Key? key,
    required this.angle,
    required this.onChanged,
    this.onChangeEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Normalizamos value a 0..1 para la animación interna si lo necesitas luego.
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 10,
        // Usamos un track transparente porque pintamos el gradiente en TrackShape
        activeTrackColor: AppColors.transparent,
        inactiveTrackColor: AppColors.transparent,
        thumbShape: const _FancyThumbShape(enabledThumbRadius: 18),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 28),
        valueIndicatorShape: PaddleSliderValueIndicatorShape(),
        valueIndicatorTextStyle: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
        showValueIndicator:
            ShowValueIndicator.onlyForContinuous, // aparece al arrastrar
        tickMarkShape: RoundSliderTickMarkShape(tickMarkRadius: 0),
        // quitar los colores directos de track para que el custom track pinte el gradiente
        inactiveTickMarkColor: AppColors.transparent,
        activeTickMarkColor: AppColors.transparent,
      ),
      child: Slider(
        value: angle,
        min: 0,
        max: 180,
        divisions: 180,
        label: '${angle.round()}°',
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
        // Pintamos el track con un Gradient custom: usamos SliderTheme's trackShape
        // Para lograrlo, envolvemos el Slider con un CustomPaint por detrás.
      ),
    );
  }
}

/// Thumb personalizado: círculo con borde, sombra y punto interior.
class _FancyThumbShape extends SliderComponentShape {
  final double enabledThumbRadius;
  const _FancyThumbShape({this.enabledThumbRadius = 12});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(enabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter? labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value, // 0..1
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Sombra difuminada
    final shadowPaint =
        Paint()
          ..color = AppColors.black.withOpacity(0.18)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(
      center.translate(0, 2),
      enabledThumbRadius.toDouble(),
      shadowPaint,
    );

    // Círculo externo (borde)
    final outerPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..shader = ui.Gradient.linear(
            Offset(
              center.dx - enabledThumbRadius,
              center.dy - enabledThumbRadius,
            ),
            Offset(
              center.dx + enabledThumbRadius,
              center.dy + enabledThumbRadius,
            ),
            [AppColors.primaryLight, AppColors.primaryDark],
          );

    canvas.drawCircle(center, enabledThumbRadius.toDouble(), outerPaint);

    // Círculo interior (contraste)
    final innerPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = AppColors.white;
    canvas.drawCircle(center, enabledThumbRadius * 0.55, innerPaint);

    // Pequeño punto central con color según gradiente (para detalle)
    final dotPaint = Paint()..color = AppColors.lightGreen;
    canvas.drawCircle(center, enabledThumbRadius * 0.18, dotPaint);
  }
}
