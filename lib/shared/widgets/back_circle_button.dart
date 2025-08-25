import 'package:flutter/material.dart';

import '../../theme/app_color.dart';

class BackCircleButton extends StatelessWidget {
  final VoidCallback onTap;

  const BackCircleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 6.0),
      child: Material(
        color: AppColors.primaryLight,
        elevation: 0,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(Icons.arrow_back, size: 28, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
