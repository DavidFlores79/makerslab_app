import 'package:flutter/material.dart';

import '../../../theme/app_color.dart';

class InitialView extends StatelessWidget {
  const InitialView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bluetooth_searching,
            size: 50,
            color: AppColors.blueAccent,
          ),
          SizedBox(height: 16),
          Text(
            'Presiona el ícono de Bluetooth para conectar con el ESP32',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
