import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/snackbar_service.dart';
import '../../../../core/validators/px_validators.dart';
import '../../../../shared/widgets/index.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ChangePasswordPage extends StatelessWidget {
  static const routeName = '/change-password';

  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final String phone;

  ChangePasswordPage({super.key, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PxBackAppBar(
        backLabel: '',
        onBackPressed: () => context.go(HomePage.routeName),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            SnackbarService().show(message: 'Contraseña cambiada con éxito');
            context.read<AuthBloc>().add(
              SigninWithPhoneRequested(phone, _newPasswordController.text),
            );
            context.go(HomePage.routeName);
          } else if (state is AuthError) {
            SnackbarService().show(message: state.message);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTitleText(context),
                    const SizedBox(height: 8),
                    _buildNewPasswordField(context),
                    const SizedBox(height: 20),
                    _buildConfirmNewPasswordField(context),
                    const SizedBox(height: 20),
                    MainAppButton(
                      label: 'Cambiar Contraseña',
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        context.read<AuthBloc>().add(
                          ChangePasswordRequested(
                            _confirmPasswordController.text,
                            _newPasswordController.text,
                          ),
                        );
                      },
                    ),
                    if (state is AuthLoading) const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleText(BuildContext context) {
    return PXCenteredSectionTitle(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      title: AppLocalizations.of(context)!.create_new_password_label,
      subtitle: AppLocalizations.of(context)!.create_new_password_help_message,
      textAlignSubtitle: TextAlign.center,
    );
  }

  Widget _buildConfirmNewPasswordField(BuildContext context) {
    return PXCustomTextField(
      labelText: AppLocalizations.of(context)!.confirm_password_label,
      hintText: AppLocalizations.of(context)!.confirm_password_hint,
      obscureText: true,
      validator:
          (value) => PXAppValidators.confirmPassword(
            value,
            _newPasswordController.text,
          ),
      onChanged: (value) {
        _confirmPasswordController.text = value;
      },
    );
  }

  Widget _buildNewPasswordField(BuildContext context) {
    return PXCustomTextField(
      labelText: AppLocalizations.of(context)!.new_password_label,
      hintText: AppLocalizations.of(context)!.new_password_label,
      obscureText: true,
      validator: (value) => PXAppValidators.password(value),
      onChanged: (value) {
        _newPasswordController.text = value;
      },
    );
  }
}
