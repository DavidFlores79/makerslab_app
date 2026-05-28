// ABOUTME: This file contains the ForgotPasswordPage for initiating password reset
// ABOUTME: It collects the user's country code and phone number to send a reset OTP

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:makerslab_app/features/auth/presentation/pages/otp_page.dart';

import '../../../../core/ui/snackbar_service.dart';
import '../../../../core/validators/px_validators.dart';
import '../../../../shared/widgets/index.dart';
import '../../../../utils/util_image.dart';
import '../../../catalogs/data/models/country_model.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/app_country_dropdown.dart';

class ForgotPasswordPage extends StatefulWidget {
  static const routeName = '/forgot-password';

  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _countryCode = '52';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _fullPhone {
    final code =
        _countryCode.startsWith('+') ? _countryCode : '+$_countryCode';
    return '$code${_phoneController.text}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PxBackAppBar(),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is ForgotPasswordSuccess) {
            SnackbarService().show(message: state.message);
            context.push(
              OtpPage.routeName,
              extra: {
                'userId': state.userId,
                'phone': _fullPhone,
                'isForForgotPassword': true,
              },
            );
          } else if (state is ForgotPasswordFailure) {
            SnackbarService().show(message: state.message);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogo(context),
                    _buildWelcomeText(context),
                    const SizedBox(height: 20),
                    _buildCountryDropdown(context),
                    const SizedBox(height: 20),
                    _buildPhoneField(context),
                    const SizedBox(height: 20),
                    _buildSendCodeButton(context, state),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Image.asset(
      UtilImage.LOGO_MAIN,
      fit: BoxFit.contain,
      height: 150,
      width: size.width * 0.5,
    );
  }

  Widget _buildWelcomeText(BuildContext context) {
    return PXSectionTitle(
      title: AppLocalizations.of(context)!.restore_password_label,
      subtitle: AppLocalizations.of(context)!.restore_help_message,
    );
  }

  Widget _buildCountryDropdown(BuildContext context) {
    return AppCountryDropdown(
      labelText: AppLocalizations.of(context)!.country_label,
      onChanged: (CountryModel? country) {
        if (country != null && country.phoneCode != null) {
          setState(() {
            _countryCode = country.phoneCode!;
          });
        }
      },
      validator: (CountryModel? value) {
        if (value == null) {
          return AppLocalizations.of(context)!.select_option_error;
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField(BuildContext context) {
    return PXCustomTextField(
      labelText: AppLocalizations.of(context)!.cellphone_number_label,
      hintText: AppLocalizations.of(context)!.cellphone_number_help_message,
      keyboardType: TextInputType.number,
      validator: (value) => PXAppValidators.phone(value),
      onChanged: (value) {
        _phoneController.text = value;
      },
    );
  }

  Widget _buildSendCodeButton(BuildContext context, AuthState state) {
    return MainAppButton(
      isLoading: state is ForgotPasswordInProgress,
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          FocusScope.of(context).unfocus();
          context.read<AuthBloc>().add(
            ForgotPasswordRequested(_fullPhone),
          );
        }
      },
      label: AppLocalizations.of(context)!.send_label,
    );
  }
}
