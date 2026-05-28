// ABOUTME: This file contains the RegisterPage with multi-step registration form
// ABOUTME: Manages page navigation across 3 steps: name, phone/country, password

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../core/ui/snackbar_service.dart';
import '../../../../di/service_locator.dart';
import '../../../../shared/widgets/index.dart';
import '../../../../theme/app_color.dart';
import '../../../../utils/util_image.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../bloc/register/register_cubit.dart';
import '../bloc/register/register_state.dart';
import '../widgets/index.dart';
import 'login_page.dart';
import 'otp_page.dart';

class RegisterPage extends StatefulWidget {
  static const routeName = '/register';

  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _pageController = PageController();

  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  late final List<Widget> _steps;

  @override
  void initState() {
    super.initState();
    _steps = [
      Form(key: _formKeys[0], child: RegisterStep1()),
      Form(key: _formKeys[1], child: RegisterStep2()),
      Form(key: _formKeys[2], child: RegisterStep3()),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RegisterCubit>(),
      child: Scaffold(
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, authState) {
            if (authState is RegistrationPending) {
              context.go(
                OtpPage.routeName,
                extra: {
                  'phone': authState.phone,
                  'registrationId': authState.registrationId,
                  'message': authState.message,
                },
              );
            } else if (authState is AuthError) {
              _pageController.jumpToPage(0);
              context.read<RegisterCubit>().reset();
              SnackbarService().show(message: authState.message);
            }
          },
          child: BlocBuilder<RegisterCubit, RegisterState>(
            builder: (context, state) {
              return Center(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLogo(context),
                        const SizedBox(height: 20),
                        PXSectionTitle(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          title: AppLocalizations.of(context)!.complete_registration_data_label,
                          subtitle: '',
                        ),
                        SizedBox(
                          height: 270,
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: _steps,
                          ),
                        ),
                        SmoothPageIndicator(
                          controller: _pageController,
                          count: _steps.length,
                          effect: const WormEffect(
                            dotHeight: 15,
                            dotWidth: 15,
                            activeDotColor: AppColors.primary,
                            dotColor: AppColors.gray200,
                          ),
                        ),
                        const SizedBox(height: 20),
                        MainAppButton(
                          onPressed: () {
                            final currentStep = state.step;
                            if (_formKeys[currentStep].currentState!.validate()) {
                              if (currentStep >= 2) {
                                context.read<AuthBloc>().add(
                                  RegisterRequested(
                                    name: state.name ?? '',
                                    phone: state.fullPhoneNumber ?? '',
                                    password: state.password ?? '',
                                  ),
                                );
                              } else {
                                context.read<RegisterCubit>().nextStep();
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                );
                              }
                            }
                          },
                          label: state.step >= 2
                              ? AppLocalizations.of(context)!.sign_up_label
                              : AppLocalizations.of(context)!.next,
                        ),
                        _buildReturnToLoginButton(context),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Image.asset(
      UtilImage.LOGO_MAIN,
      fit: BoxFit.contain,
      height: 150,
      width: size.width * 0.35,
    );
  }

  Widget _buildReturnToLoginButton(BuildContext context) {
    return TextButton(
      onPressed: () => context.go(LoginPage.routeName),
      child: Text(
        AppLocalizations.of(context)!.already_have_account_label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary),
      ),
    );
  }
}
