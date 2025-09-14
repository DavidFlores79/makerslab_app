import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/ui/snackbar_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ChangePasswordPage extends StatelessWidget {
  static const routeName = '/change-password';

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            SnackbarService().show(message: 'Contraseña cambiada con éxito');
            Navigator.pop(context);
          } else if (state is AuthError) {
            SnackbarService().show(message: state.message);
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _oldPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña actual',
                  ),
                ),
                TextField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Nueva contraseña',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(
                      ChangePasswordRequested(
                        _oldPasswordController.text,
                        _newPasswordController.text,
                      ),
                    );
                  },
                  child: const Text('Cambiar contraseña'),
                ),
                if (state is AuthLoading) const CircularProgressIndicator(),
              ],
            ),
          );
        },
      ),
    );
  }
}
