import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'onboarding_step_widget.dart';

class OnboardingStep2 extends StatelessWidget {
  const OnboardingStep2({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingStepWidget(
      title: AppLocalizations.of(context)!.onboarding_step2_title,
      description: AppLocalizations.of(context)!.onboarding_step2_description,
    );
  }
}
