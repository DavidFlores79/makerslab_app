import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../../core/validators/px_validators.dart';
import '../../../../../shared/widgets/index.dart';
import '../../bloc/register/register_cubit.dart';

class RegisterStep1 extends StatelessWidget {
  const RegisterStep1({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PXCustomTextField(
          labelText: AppLocalizations.of(context)!.first_name_label,
          hintText: AppLocalizations.of(context)!.first_name_hint,
          keyboardType: TextInputType.name,
          validator: (value) => PXAppValidators.name(value),
          onChanged: (value) {
            context.read<RegisterCubit>().updateName(value);
          },
        ),
        const SizedBox(height: 20),
        PXCustomTextField(
          labelText: AppLocalizations.of(context)!.first_surname_label,
          hintText: AppLocalizations.of(context)!.first_surname_hint,
          keyboardType: TextInputType.name,
          validator: (value) => PXAppValidators.name(value),
          onChanged: (value) {
            context.read<RegisterCubit>().updateFirstSurname(value);
          },
        ),
        const SizedBox(height: 20),
        PXCustomTextField(
          labelText: AppLocalizations.of(context)!.second_surname_label,
          hintText: AppLocalizations.of(context)!.second_surname_hint,
          keyboardType: TextInputType.name,
          //campo opcional pero si existe debe ser válido y mayor a 2
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              return PXAppValidators.name(value);
            }
            return null;
          },
          onChanged: (value) {
            context.read<RegisterCubit>().updateSecondSurname(value);
          },
        ),
      ],
    );
  }
}
