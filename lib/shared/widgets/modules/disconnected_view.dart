import 'package:flutter/material.dart';

import '../../../theme/app_color.dart';

class DisconnectedView extends StatelessWidget {
  const DisconnectedView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bluetooth_disabled, size: 50, color: AppColors.gray600),
          SizedBox(height: 16),
          Text(
            'Desconectado',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Presiona el ícono de Bluetooth para reconectar (DV)',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
