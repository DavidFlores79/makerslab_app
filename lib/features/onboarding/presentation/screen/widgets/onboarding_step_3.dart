import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'onboarding_step_widget.dart';

class OnboardingStep3 extends StatelessWidget {
  const OnboardingStep3({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingStepWidget(
      title: AppLocalizations.of(context)!.onboarding_step3_title,
      description: AppLocalizations.of(context)!.onboarding_step3_description,
    );
  }
}
