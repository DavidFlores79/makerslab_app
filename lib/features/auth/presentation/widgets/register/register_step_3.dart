import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../../core/validators/px_validators.dart';
import '../../../../../theme/app_color.dart';
import '../../../../legal/presentation/pages/privacy_policy_page.dart';
import '../../../../legal/presentation/pages/terms_conditions_page.dart';
import '../../../../../shared/widgets/index.dart';
import '../../bloc/register/register_cubit.dart';

class RegisterStep3 extends StatelessWidget {
  const RegisterStep3({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PXCustomTextField(
          labelText: AppLocalizations.of(context)!.password_label,
          hintText: AppLocalizations.of(context)!.password_hint,
          keyboardType: TextInputType.visiblePassword,
          obscureText: true,
          validator: (value) => PXAppValidators.password(value),
          onChanged: (value) {
            context.read<RegisterCubit>().updatePassword(value);
          },
        ),
        const SizedBox(height: 20),
        PXCustomTextField(
          labelText: AppLocalizations.of(context)!.confirm_password_label,
          hintText: AppLocalizations.of(context)!.confirm_password_hint,
          keyboardType: TextInputType.visiblePassword,
          obscureText: true,
          validator:
              (value) => PXAppValidators.confirmPassword(
                value,
                context.read<RegisterCubit>().state.password,
              ),
          onChanged: (value) {
            context.read<RegisterCubit>().updateConfirmPassword(value);
          },
        ),
        const SizedBox(height: 20),
        _buildTermsCheckbox(context),
      ],
    );
  }

  Widget _buildTermsCheckbox(BuildContext context) {
    final cubit = context.read<RegisterCubit>();
    final state = context.watch<RegisterCubit>().state;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: state.acceptedTerms,
          onChanged: (value) {
            cubit.updateAcceptedTerms(value ?? false);
          },
          activeColor: AppColors.primary,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.gray600,
                ),
                children: [
                  const TextSpan(text: 'Acepto el '),
                  TextSpan(
                    text: AppLocalizations.of(context)!.privacy_notice_label,
                    style: const TextStyle(
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        context.push(PrivacyPolicyPage.routeName);
                      },
                  ),
                  const TextSpan(text: ' así como los '),
                  TextSpan(
                    text: AppLocalizations.of(context)!.terms_conditions_label,
                    style: const TextStyle(
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        context.push(TermsConditionsPage.routeName);
                      },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
