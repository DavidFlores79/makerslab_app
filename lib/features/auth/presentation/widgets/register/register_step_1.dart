// ABOUTME: This file contains the RegisterStep1 widget
// ABOUTME: It displays the first step of registration form with name input field

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
          labelText: AppLocalizations.of(context)!.name_label,
          hintText: AppLocalizations.of(context)!.name_hint,
          keyboardType: TextInputType.name,
          validator: (value) => PXAppValidators.name(value),
          onChanged: (value) {
            context.read<RegisterCubit>().updateName(value);
          },
        ),
      ],
    );
  }
}
