import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../../core/validators/px_validators.dart';
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
      ],
    );
  }
}
