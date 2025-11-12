import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../shared/widgets/index.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'personal_data_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  static const String routeName = "/profile";
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final String? userName =
            authState is Authenticated
                ? (authState.user.name ?? authState.user.phone)
                : null;
        final String? userImage =
            authState is Authenticated ? authState.user.image : null;

        return Scaffold(
          appBar: PxMainAppBar(userName: userName, userImage: userImage),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                _BuildAccountSection(),
                const SizedBox(height: 30),
                _BuildSupportSection(),
                const SizedBox(height: 30),
                _BuildLegalSection(),
                const SizedBox(height: 30),
                _BuildAppSection(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BuildAccountSection extends StatelessWidget {
  const _BuildAccountSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final isAuthenticated = authState is Authenticated;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileItemCard(
              title: 'Datos personales',
              subtitle:
                  isAuthenticated
                      ? 'Información de perfil'
                      : 'Inicia sesión para ver tu perfil',
              icon: Symbols.person,
              onTap:
                  isAuthenticated
                      ? () => context.push(PersonalDataPage.routeName)
                      : null,
            ),
            ProfileItemCard(
              title: 'Configuración',
              subtitle: 'Ajustes y preferencias',
              icon: Symbols.settings,
              onTap: () => context.push(SettingsPage.routeName),
            ),
          ],
        );
      },
    );
  }
}

class _BuildSupportSection extends StatelessWidget {
  const _BuildSupportSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final isAuthenticated = authState is Authenticated;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileItemCard(
              title: 'Centro de Ayuda',
              subtitle: 'Preguntas frecuentes y guía',
              icon: Symbols.help,
              onTap: () {
                // TODO: Navigate to help center
              },
            ),
            ProfileItemCard(
              title: 'Contactar Soporte',
              subtitle:
                  isAuthenticated
                      ? 'Chat y asistencia'
                      : 'Inicia sesión para contactar soporte',
              icon: Symbols.support_agent,
              onTap:
                  isAuthenticated
                      ? () {
                        // TODO: Navigate to contact support
                      }
                      : null,
            ),
          ],
        );
      },
    );
  }
}

class _BuildLegalSection extends StatelessWidget {
  const _BuildLegalSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileItemCard(
          title: 'Términos y condiciones',
          subtitle: 'Condiciones de uso',
          icon: Symbols.description,
          onTap: () {
            // TODO: Navigate to terms and conditions
          },
        ),
        ProfileItemCard(
          title: 'Política de Privacidad',
          subtitle: 'Manejo de datos',
          icon: Symbols.privacy_tip,
          onTap: () {
            // TODO: Navigate to privacy policy
          },
        ),
      ],
    );
  }
}

class _BuildAppSection extends StatefulWidget {
  const _BuildAppSection();

  @override
  State<_BuildAppSection> createState() => _BuildAppSectionState();
}

class _BuildAppSectionState extends State<_BuildAppSection> {
  String version = 'Desconocida';

  @override
  void initState() {
    super.initState();
    getAppVersion();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileItemCard(
          title: 'Calificar App',
          subtitle: 'Ayúdanos a mejorar',
          icon: Symbols.star,
          onTap: () {
            // TODO: Open app store for rating
          },
        ),
        ProfileItemCard(
          title: 'Compartir App',
          subtitle: 'Invita a tus amigos',
          icon: Symbols.share,
          onTap: () {
            // TODO: Share app
          },
        ),
        ProfileItemCard(
          title: 'Versión',
          subtitle: version,
          icon: Symbols.info,
          onTap: () {
            // TODO: Show version details or changelog
          },
        ),
      ],
    );
  }

  Future<void> getAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        version = '${packageInfo.version} (Build ${packageInfo.buildNumber})';
      });
    } catch (e) {
      version = 'Desconocida';
    }
  }
}

class ProfileItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const ProfileItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = onTap == null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      decoration: BoxDecoration(
        color:
            isDisabled
                ? theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                )
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isDisabled
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: Icon(
            icon,
            size: 24,
            color:
                isDisabled
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                    : theme.colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color:
                isDisabled
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                    : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color:
                isDisabled
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                    : theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.chevron_right,
          color:
              isDisabled
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.2)
                  : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
