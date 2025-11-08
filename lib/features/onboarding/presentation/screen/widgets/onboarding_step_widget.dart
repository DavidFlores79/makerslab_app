import 'package:flutter/material.dart';

import '../../../../../theme/app_color.dart';
import '../../../../../utils/util_image.dart';

class OnboardingStepWidget extends StatelessWidget {
  final String title;
  final String description;
  const OnboardingStepWidget({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 150),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            UtilImage.PAISAMEX_LOGO_WHITE,
            fit: BoxFit.fitWidth,
            width: size.width * 0.5,
          ),
          const SizedBox(height: 30),
          Text(
            title,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: AppColors.gray300,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.start,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.gray300),
            textAlign: TextAlign.start,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
