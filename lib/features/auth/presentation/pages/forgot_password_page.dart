import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:makerslab_app/features/auth/presentation/pages/otp_page.dart';

import '../../../../core/ui/snackbar_service.dart';
import '../../../../core/validators/px_validators.dart';
import '../../../../shared/widgets/index.dart';
import '../../../../utils/util_image.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ForgotPasswordPage extends StatelessWidget {
  static const routeName = '/forgot-password';

  final _phoneController = TextEditingController();

  ForgotPasswordPage({super.key});

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
                'phone': _phoneController.text,
                'isForForgotPassword': true,
              },
            );
          } else if (state is ForgotPasswordFailure) {
            SnackbarService().show(message: state.message);
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(context),
                _buildWelcomeText(context),
                const SizedBox(height: 20),
                _buildPhoneField(context),
                const SizedBox(height: 20),
                _buildSendCodeButton(context, state),
              ],
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
      fit: BoxFit.fitWidth,
      width: size.width * 0.5,
    );
  }

  Widget _buildWelcomeText(BuildContext context) {
    return PXSectionTitle(
      title: AppLocalizations.of(context)!.restore_password_label,
      subtitle: AppLocalizations.of(context)!.restore_help_message,
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
    debugPrint('>>> Phone to send: ${_phoneController.text}');
    return MainAppButton(
      isLoading: state is ForgotPasswordInProgress,
      onPressed: () {
        context.read<AuthBloc>().add(
          ForgotPasswordRequested(_phoneController.text),
        );
      },
      label: AppLocalizations.of(context)!.send_label,
    );
  }
}
