import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../../core/validators/px_validators.dart';
import '../../../../../shared/widgets/index.dart';
import '../../../../catalogs/data/models/country_model.dart';
import '../../bloc/register/register_cubit.dart';
import '../app_country_dropdown.dart';

class RegisterStep2 extends StatefulWidget {
  const RegisterStep2({super.key});

  @override
  State<RegisterStep2> createState() => _RegisterStep2State();
}

class _RegisterStep2State extends State<RegisterStep2> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        AppCountryDropdown(
          labelText: AppLocalizations.of(context)!.country_label,
          onChanged: (CountryModel? country) {
            if (country != null) {
              context.read<RegisterCubit>().updateCountryCode(country);
            }
          },
          validator: (CountryModel? value) {
            if (value == null) {
              return AppLocalizations.of(context)!.select_option_error;
            }
            return null;
          },
        ),
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
