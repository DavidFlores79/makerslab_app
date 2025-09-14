import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../core/ui/snackbar_service.dart';
import '../../../../di/service_locator.dart';
import '../../../../shared/images/tri_circle_header.dart';
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

class RegisterPage extends StatelessWidget {
  static const routeName = '/register';

  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  late final List<Widget> steps;

  RegisterPage({super.key}) {
    steps = [
      Form(key: _formKeys[0], child: RegisterStep1()),
      Form(key: _formKeys[1], child: RegisterStep2()),
      Form(key: _formKeys[2], child: RegisterStep3()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pageController = PageController();

    return BlocProvider(
      create: (_) => getIt<RegisterCubit>(),
      child: Scaffold(
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, authState) {
            if (authState is RegistrationPending) {
              // navegar a OTP con go_router (param userId), pasamos phone por extra
              debugPrint(
                '>>> Navegando a OTP para userId: ${authState.userId}',
              );
              context.go(
                OtpPage.routeName,
                extra: {'phone': authState.phone, 'userId': authState.userId},
              );
            } else if (authState is AuthError) {
              SnackbarService().show(message: authState.message);
              pageController.jumpToPage(0);
              context.read<RegisterCubit>().reset();
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
                        TriCircleHeader(
                          centerImage: AssetImage(
                            UtilImage.SIGN_IN_BACKGROUND_1,
                          ),
                          leftImage: AssetImage(UtilImage.SIGN_IN_BACKGROUND_4),
                          rightImage: AssetImage(
                            UtilImage.SIGN_IN_BACKGROUND_2,
                          ),
                        ),
                        PXSectionTitle(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          title:
                              AppLocalizations.of(
                                context,
                              )!.complete_registration_data_label,
                          subtitle: '',
                        ),
                        SizedBox(
                          height: 270, // Ajusta según el diseño de tus steps
                          child: PageView(
                            controller: pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: steps,
                          ),
                        ),
                        SmoothPageIndicator(
                          controller: pageController,
                          count: steps.length,
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

                            // validar campos del step actual
                            if (_formKeys[currentStep].currentState!
                                .validate()) {
                              if (currentStep >= 2) {
                                // último step: registrar
                                context.read<AuthBloc>().add(
                                  RegisterRequested(
                                    firstName: state.firstName ?? '',
                                    firstSurname: state.firstSurname ?? '',
                                    secondSurname: state.secondSurname ?? '',
                                    phone: state.phone ?? '',
                                    password: state.password ?? '',
                                    confirmPassword:
                                        state.confirmPassword ?? '',
                                  ),
                                );
                              } else {
                                // avanzar al siguiente step
                                context.read<RegisterCubit>().nextStep();
                                pageController.nextPage(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                );
                              }
                            }
                          },
                          label:
                              state.step >= 2
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
      UtilImage.PAISAMEX_LOGO_GREEN,
      fit: BoxFit.fitWidth,
      width: size.width * 0.5,
    );
  }

  Widget _buildReturnToLoginButton(BuildContext context) {
    return TextButton(
      onPressed: () => context.go(LoginPage.routeName),
      child: Text(
        AppLocalizations.of(context)!.already_have_account_label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
      ),
    );
  }
}
