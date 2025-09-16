import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../core/ui/snackbar_service.dart';
import '../../../../core/validators/px_validators.dart';
import '../../../../shared/widgets/index.dart';
import '../../../../theme/app_color.dart';
import '../../../../utils/util_image.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'forgot_password_page.dart';
import 'otp_page.dart';
import 'register_page.dart';

class LoginPage extends StatelessWidget {
  static const routeName = '/login';

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            SnackbarService().show(
              message: AppLocalizations.of(context)!.sign_in_label_welcome(
                '${state.user.name ?? state.user.phone}',
              ),
            );
            context.go(HomePage.routeName);
          } else if (state is AuthError) {
            SnackbarService().show(message: state.message);
          }
        },
        builder: (context, state) {
          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(context),
                      const SizedBox(height: 20),
                      _buildWelcomeText(context),
                      const SizedBox(height: 20),
                      _buildPhoneField(context),
                      SizedBox(height: 20),
                      _buildPasswordField(context),
                      const SizedBox(height: 20),
                      _buildForgotPasswordButton(context),
                      const SizedBox(height: 10),
                      _buildLoginButton(context, state),
                      const SizedBox(height: 10),
                      _buildRegisterButton(context),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  onLoginRequest(BuildContext context) {
    context.read<AuthBloc>().add(
      SigninWithPhoneRequested(_phoneController.text, _passwordController.text),
    );
  }

  Widget _buildWelcomeText(BuildContext context) {
    return PXSectionTitle(
      title: AppLocalizations.of(context)!.welcome_app_label,
      subtitle: AppLocalizations.of(context)!.login_help_message,
    );
  }

  Widget _buildPhoneField(BuildContext context) {
    return PXCustomTextField(
      labelText: AppLocalizations.of(context)!.cellphone_number_label,
      hintText: AppLocalizations.of(context)!.cellphone_number_help_message,
      keyboardType: TextInputType.phone,
      validator: (value) => PXAppValidators.phone(value),
      onChanged: (value) {
        _phoneController.text = value;
      },
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return PXCustomTextField(
      hintText: AppLocalizations.of(context)!.password_help_message,
      labelText: AppLocalizations.of(context)!.password_label,
      validator: (value) => PXAppValidators.passwordLogin(value),
      onChanged: (value) {
        _passwordController.text = value;
      },
      obscureText: true,
    );
  }

  Widget _buildLoginButton(BuildContext context, AuthState state) {
    return MainAppButton(
      isLoading: state is AuthLoading,
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          FocusScope.of(context).unfocus();
          onLoginRequest(context);
        }
      },
      label: AppLocalizations.of(context)!.sign_in_label,
    );
  }

  Widget _buildLogo(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Image.asset(
      UtilImage.LOGO_MAIN,
      fit: BoxFit.fitWidth,
      width: size.width * 0.5,
    );
  }

  Widget _buildForgotPasswordButton(BuildContext context) {
    return TextButton(
      onPressed: () => context.push(ForgotPasswordPage.routeName),
      child: Text(
        AppLocalizations.of(context)!.forgot_password_label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
      ),
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    return TextButton(
      onPressed: () => context.go(RegisterPage.routeName),
      child: Text(
        AppLocalizations.of(context)!.dont_have_account_label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
      ),
    );
  }
}
