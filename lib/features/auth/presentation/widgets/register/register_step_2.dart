import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../../core/validators/px_validators.dart';
import '../../../../../shared/widgets/index.dart';
import '../../bloc/register/register_cubit.dart';

class RegisterStep2 extends StatelessWidget {
  const RegisterStep2({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // PXCustomTextField(
        //   labelText: 'País',
        //   hintText: 'Ingresa tu país',
        //   keyboardType: TextInputType.name,
        //   validator: (value) => PXAuthValidators.name(value),
        //   onChanged: (value) {
        //     context.read<RegisterCubit>().updateName(value);
        //   },
        // ),
        const SizedBox(height: 20),
        PXCustomTextField(
          labelText: AppLocalizations.of(context)!.phone_label,
          hintText: AppLocalizations.of(context)!.phone_hint,
          keyboardType: TextInputType.phone,
          validator: (value) => PXAppValidators.phone(value),
          onChanged: (value) {
            context.read<RegisterCubit>().updatePhone(value);
          },
        ),
        const SizedBox(height: 20),
        PXCustomTextField(
          labelText: AppLocalizations.of(context)!.confirm_phone_label,
          hintText: AppLocalizations.of(context)!.confirm_phone_hint,
          keyboardType: TextInputType.phone,
          validator:
              (value) => PXAppValidators.confirmPhone(
                value,
                context.read<RegisterCubit>().state.phone,
              ),
          onChanged: (value) {
            context.read<RegisterCubit>().updateConfirmPhone(value);
          },
        ),
      ],
    );
  }
}
