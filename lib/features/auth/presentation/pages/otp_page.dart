import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../core/ui/snackbar_service.dart';
import '../../../../shared/widgets/index.dart';
import '../../../../utils/util_image.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/otp/otp_bloc.dart';
import '../bloc/otp/otp_event.dart';
import '../bloc/otp/otp_state.dart';

class OtpPage extends StatefulWidget {
  static const routeName = '/auth/otp';
  final String userId;
  final String phone;

  const OtpPage({super.key, required this.userId, required this.phone});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _codeController = TextEditingController();
  final StreamController<ErrorAnimationType> _errorController =
      StreamController<ErrorAnimationType>();
  late OtpBloc _otpBloc;
  bool _blocInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_blocInitialized) {
      _otpBloc = context.read<OtpBloc>();
      _blocInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _otpBloc.add(OtpStartTimer(seconds: 60));
        }
      });
    }
  }

  @override
  void dispose() {
    if (!_errorController.isClosed) {
      _errorController.close();
    }
    try {
      _codeController.dispose();
    } catch (_) {}
    super.dispose();
  }

  void _showSnack(String message) {
    if (mounted) SnackbarService().show(message: message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: BlocConsumer<OtpBloc, OtpState>(
            listener: _onOtpStateChanged,
            builder: (context, state) {
              final secondsLeft = (state is OtpInitial) ? state.secondsLeft : 0;
              final canResend = (state is OtpInitial) ? state.canResend : false;
              final isLoading = state is OtpLoading;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(context),
                  _buildTitleText(context),
                  const SizedBox(height: 8),
                  _buildPinCodeField(theme),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.dont_receive_code_label,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child:
                        secondsLeft > 0
                            ? TextButton(
                              onPressed: null,
                              child: Text(
                                '${AppLocalizations.of(context)!.wait_label} ${secondsLeft}s',
                                style: theme.textTheme.bodyMedium,
                              ),
                            )
                            : TextButton(
                              onPressed:
                                  canResend && !isLoading
                                      ? () => _otpBloc.add(
                                        OtpResendPressed(id: widget.userId),
                                      )
                                      : null,
                              child: Text(
                                AppLocalizations.of(context)!.resend_code_label,
                              ),
                            ),
                  ),
                  const SizedBox(height: 20),
                  MainAppButton(
                    onPressed:
                        isLoading
                            ? null
                            : () => _otpBloc.add(
                              OtpConfirmPressed(
                                id: widget.userId,
                                code: _codeController.text.trim(),
                              ),
                            ),
                    isLoading: isLoading,
                    label: AppLocalizations.of(context)!.confirm_label,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: Text(
                      AppLocalizations.of(context)!.back_to_start_label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _onOtpStateChanged(BuildContext context, OtpState state) {
    if (state is OtpResendSent) {
      _showSnack(AppLocalizations.of(context)!.resend_code_label);
      return;
    }

    if (state is OtpFailure) {
      if (!_errorController.isClosed) {
        _errorController.add(ErrorAnimationType.shake);
      }
      _codeController.clear();
      _showSnack(state.message);
      return;
    }

    if (state is OtpConfirmSuccess) {
      _showSnack(
        AppLocalizations.of(context)!.account_verified_successfully_label,
      );
      _codeController.clear();
      try {
        final authBloc = context.read<AuthBloc>();
        authBloc.add(
          RegistrationConfirmed(user: state.user, token: state.token),
        );
      } catch (_) {}
      if (mounted) {
        context.go(HomePage.routeName);
      }
    }
  }

  Widget _buildLogo(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Image.asset(
      UtilImage.PAISAMEX_LOGO_GREEN,
      fit: BoxFit.fitWidth,
      width: size.width * 0.5,
    );
  }

  Widget _buildTitleText(BuildContext context) {
    return PXCenteredSectionTitle(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      title: AppLocalizations.of(context)!.verification_code_label,
      subtitle: AppLocalizations.of(
        context,
      )!.verification_code_help_message(widget.phone),
      textAlignSubtitle: TextAlign.center,
    );
  }

  Widget _buildPinCodeField(ThemeData theme) {
    return PinCodeTextField(
      appContext: context,
      length: 6,
      animationType: AnimationType.scale,
      controller: _codeController,
      keyboardType: TextInputType.number,
      errorAnimationController: _errorController,
      animationDuration: const Duration(milliseconds: 200),
      enableActiveFill: true,
      autoFocus: true,
      enablePinAutofill: true,
      onChanged: (value) {
        _otpBloc.add(OtpCodeChanged(value));
      },
      onCompleted: (value) {
        debugPrint('Código OTP completado: $value');
        _otpBloc.add(OtpConfirmPressed(id: widget.userId, code: value));
      },
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        borderRadius: BorderRadius.circular(8),
        fieldHeight: 52,
        fieldWidth: 44,
        activeFillColor: Colors.white,
        inactiveFillColor: Colors.white,
        selectedFillColor: Colors.white,
        activeColor: theme.primaryColor,
        selectedColor: theme.primaryColor,
        inactiveColor: Colors.grey.shade300,
      ),
      pastedTextStyle: TextStyle(
        color: theme.textTheme.bodyLarge?.color,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
