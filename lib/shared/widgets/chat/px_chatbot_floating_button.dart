// --- PxChatBotFloatingButton queda igual (solo muestra el modal) ---
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:makerslab_app/core/ui/snackbar_service.dart';

import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../features/auth/presentation/pages/login_page.dart';
import '../../../features/chat/presentation/pages/chat_content.dart';
import 'chat_modal_header.dart';

class PxChatBotFloatingButton extends StatelessWidget {
  final String moduleKey;
  const PxChatBotFloatingButton({super.key, required this.moduleKey});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        final isLoggedIn = context.read<AuthBloc>().state is Authenticated;

        if (!isLoggedIn) {
          final loginResult = await context.push(LoginPage.routeName);
          if (loginResult != true) {
            SnackbarService().show(
              message: 'Debes iniciar sesión o registrarte para usar el chat.',
            );
            return;
          }
        }

        PxChatBotModal.show(context, moduleKey: moduleKey);
      },
      child: Image.asset(
        'assets/images/brand/logo-app.png',
        width: 32,
        height: 32,
        // color: Colors.white,
      ),
    );
  }
}

// --- Modal wrapper que usa DraggableScrollableSheet ---
class PxChatBotModal {
  static void show(BuildContext context, {required String moduleKey}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // para rounded corners
      builder: (_) => _PxChatBotBottomSheet(moduleKey: moduleKey),
    );
  }
}

class _PxChatBotBottomSheet extends StatefulWidget {
  final String moduleKey;
  const _PxChatBotBottomSheet({required this.moduleKey});

  @override
  State<_PxChatBotBottomSheet> createState() => _PxChatBotBottomSheetState();
}

class _PxChatBotBottomSheetState extends State<_PxChatBotBottomSheet> {
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();

  // tamaños: ajusta según gusto
  static const double _initial = 0.98;
  static const double _min = 0.28;
  static const double _max = 0.98;

  @override
  void dispose() {
    _draggableController.dispose();
    super.dispose();
  }

  void _minimize() {
    // anima al tamaño mínimo
    _draggableController.animateTo(
      _min,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  void _expand() {
    _draggableController.animateTo(
      _max,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.vertical(top: Radius.circular(16));
    return Padding(
      padding: const EdgeInsets.only(top: 24.0), // Larger gap from top
      child: ClipRRect(
        borderRadius: borderRadius,
        child: DraggableScrollableSheet(
          controller: _draggableController,
          initialChildSize: _initial,
          minChildSize: _min,
          maxChildSize: _max,
          expand: false,
          builder: (context, scrollController) {
            return Material(
              color: Theme.of(context).canvasColor,
              child: Column(
                children: [
                  // Use ChatModalHeader instead of custom row
                  ChatModalHeader(
                    moduleKey: widget.moduleKey,
                    onMinimize: _minimize,
                    onClose: () => context.pop(),
                  ),

                  // contenido del chat (reusa ChatContent)
                  Expanded(
                    child: ChatContent(
                      moduleKey: widget.moduleKey,
                      externalScrollController: scrollController,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
