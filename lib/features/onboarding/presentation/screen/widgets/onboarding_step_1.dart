import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'onboarding_step_widget.dart';

class OnboardingStep1 extends StatelessWidget {
  const OnboardingStep1({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingStepWidget(
      title: AppLocalizations.of(context)!.onboarding_step1_title,
      description: AppLocalizations.of(context)!.onboarding_step1_description,
    );
  }
}
