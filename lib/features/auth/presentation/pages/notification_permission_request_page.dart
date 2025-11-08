// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
// import 'package:paisamex_new_design_app/theme/app_color.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import '../../../../core/ui/snackbar_service.dart';
// import '../../../../utils/util_image.dart';
// import '../../../home/presentation/pages/home_page.dart';
// import '../../../notification/presentation/bloc/notification_bloc.dart';
// import '../../../notification/presentation/bloc/notification_event.dart';
// import '../../../notification/presentation/bloc/notification_state.dart';
// import 'app_screen_scroll.dart';
// import 'login_page.dart';

// class NotificationPermissionRequestPage extends StatefulWidget {
//   static const String routeName = "/notification-permission-request";

//   const NotificationPermissionRequestPage({super.key});

//   @override
//   State<NotificationPermissionRequestPage> createState() =>
//       _NotificationPermissionRequestPageState();
// }

// class _NotificationPermissionRequestPageState
//     extends State<NotificationPermissionRequestPage>
//     with SingleTickerProviderStateMixin {
//   static const _horizontalPadding = EdgeInsets.symmetric(horizontal: 15);
//   static const _cardMargin = EdgeInsets.symmetric(horizontal: 20);
//   static const _sectionSpacing = SizedBox(height: 30);
//   late final AnimationController _controller;
//   late final Animation<double> _rotationAnimation;

//   @override
//   void initState() {
//     super.initState();
//     context.read<NotificationBloc>().add(LoadStatusEvent());
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 1200),
//       vsync: this,
//     );

//     _rotationAnimation = TweenSequence<double>([
//       TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.1), weight: 1),
//       TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.1), weight: 1),
//       TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.05), weight: 1),
//       TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.0), weight: 1),
//       TweenSequenceItem(tween: ConstantTween(0.0), weight: 2), // Pausa
//       TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.1), weight: 1),
//       TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.1), weight: 1),
//       TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.05), weight: 1),
//       TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.0), weight: 1),
//       TweenSequenceItem(tween: ConstantTween(0.0), weight: 2),
//     ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

//     // Repetir con pausa entre ciclos
//     _startShakingLoop();
//   }

//   void _startShakingLoop() async {
//     while (mounted) {
//       await _controller.forward(from: 0);
//       await Future.delayed(const Duration(seconds: 1)); // Pausa entre sacudidas
//     }
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<NotificationBloc, NotificationState>(
//       listener: (context, state) {
//         debugPrint("========> STATE: $state");
//         if (state is NotificationStatusLoaded) {
//           // context.pushReplacement('/home'); // O la ruta correspondiente
//           debugPrint("areEnabled ${state.areNotificationsEnabled}");
//           if (state.areNotificationsEnabled as bool) {
//             context.go(LoginPage.routeName);
//             SnackbarService().show(
//               message: 'Gracias por habilitar las notificaciones',
//             );
//           }
//         } else if (state is NotificationError) {
//           debugPrint("========> NotificationError ${state.message}");
//           SnackbarService().show(
//             message:
//                 'Se denegó el permiso de notificaciones. Puede habilitarlo manualmente en la sección de configuración de la aplicación.',
//           );
//           context.go(HomePage.routeName);
//         }
//       },
//       child: Scaffold(
//         body: AppScreenScroll(
//           isScrollable: false,
//           isToolbarActive: false,
//           child: Padding(
//             padding: _horizontalPadding,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 _buildTopImage(),
//                 const SizedBox(height: 20),
//                 _buildInfoCard(),
//                 const SizedBox(height: 40),
//                 _buildTitle(context),
//                 const SizedBox(height: 20),
//                 _buildDescription(context),
//                 _sectionSpacing,
//                 _buildActionButton(context),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTopImage() {
//     return Align(
//       alignment: Alignment.centerRight,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 35),
//         child: AnimatedBuilder(
//           animation: _rotationAnimation,
//           builder:
//               (_, child) => Transform.rotate(
//                 angle: _rotationAnimation.value,
//                 child: child,
//               ),
//           child: Image.asset(UtilImage.NOTIFICATION_ICON, height: 75),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCard() {
//     return Container(
//       padding: const EdgeInsets.all(10),
//       margin: _cardMargin,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(15),
//         color: AppColors.gray200,
//       ),
//       child: Row(
//         children: [
//           _buildProfileImage(),
//           const SizedBox(width: 10),
//           _buildProgressIndicators(),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfileImage() {
//     return Container(
//       width: 80,
//       height: 80,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         border: Border.all(color: Colors.white, width: 3),
//         image: const DecorationImage(
//           image: AssetImage(UtilImage.NOTIFICATION_WOMAN),
//           fit: BoxFit.cover,
//         ),
//       ),
//     );
//   }

//   Widget _buildProgressIndicators() {
//     return Flexible(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildProgressBar(widthFactor: 0.7, color: AppColors.primary),
//           const SizedBox(height: 10),
//           _buildProgressBar(widthFactor: 0.4, color: AppColors.greenLight),
//         ],
//       ),
//     );
//   }

//   Widget _buildProgressBar({
//     required double widthFactor,
//     required Color color,
//   }) {
//     return FractionallySizedBox(
//       widthFactor: widthFactor,
//       child: Container(
//         height: 10,
//         decoration: BoxDecoration(
//           color: color,
//           borderRadius: BorderRadius.circular(5),
//         ),
//       ),
//     );
//   }

//   Widget _buildTitle(BuildContext context) {
//     return Text(
//       AppLocalizations.of(context)!.enable_notifications_title,
//       style: Theme.of(context).textTheme.headlineLarge,
//       textAlign: TextAlign.center,
//     );
//   }

//   Widget _buildDescription(BuildContext context) {
//     return Text(
//       AppLocalizations.of(context)!.enable_notifications_description,
//       style: Theme.of(
//         context,
//       ).textTheme.bodyLarge?.copyWith(color: AppColors.gray700),
//       textAlign: TextAlign.center,
//     );
//   }

//   Widget _buildActionButton(BuildContext context) {
//     return TextButton(
//       onPressed: () {
//         context.read<NotificationBloc>().add(RequestPermissionEvent());
//       },
//       child: Text(
//         AppLocalizations.of(context)!.enable_notifications_button,
//         style: Theme.of(
//           context,
//         ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
//       ),
//     );
//   }
// }
