import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../shared/widgets/index.dart';
import '../../../../theme/app_color.dart';
import '../../../../utils/util_image.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import 'widgets/index.dart';

class OnboardingPage extends StatefulWidget {
  static const String routeName = "/onboarding";

  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int currentPage = 0;
  final List<Widget> steps = const [
    OnboardingStep1(),
    OnboardingStep2(),
    OnboardingStep3(),
  ];

  void _completeOnboarding(BuildContext context) {
    context.read<OnboardingBloc>().add(OnboardingCompleted());
    context.go(HomePage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(
              UtilImage.SIGN_IN_BACKGROUND_2,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              //quiero que se oscuro no claro
              color: AppColors.black3.withValues(alpha: 0.3),
            ),
          ),
          PageView(
            pageSnapping: true,
            controller: _controller,
            onPageChanged: (index) => setState(() => currentPage = index),
            children: steps,
          ),
          Container(
            alignment: const Alignment(-0.8, 0),
            child: SmoothPageIndicator(
              controller: _controller,
              count: steps.length,
              effect: const WormEffect(
                dotHeight: 15,
                dotWidth: 15,
                activeDotColor: AppColors.white,
                dotColor: AppColors.gray200,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: MainAppButton(
                onPressed:
                    currentPage >= (steps.length - 1)
                        ? () => _completeOnboarding(context)
                        : () => _controller.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        ),
                label:
                    currentPage >= (steps.length - 1)
                        ? AppLocalizations.of(context)!.start
                        : AppLocalizations.of(context)!.next,
              ),
            ),
          ),
        ],
      ),
      // bottomNavigationBar: ,
    );
  }
}
