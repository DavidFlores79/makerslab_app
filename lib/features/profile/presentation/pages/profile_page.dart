import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../shared/widgets/index.dart';
import '../../../../theme/app_color.dart';

class ProfilePage extends StatefulWidget {
  static const String routeName = "/profile";
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PxMainAppBar(),
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
          ],
        ),
      ),
    );
  }
}

class _BuildAccountSection extends StatelessWidget {
  const _BuildAccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            'Cuenta',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.gray600,
            ),
          ),
        ),
        const SizedBox(height: 15),
        ProfileItemCard(
          title: 'Información personal',
          subtitle: 'Datos de perfil y verificación',
          icon: Symbols.person,
        ),
        const Divider(color: AppColors.gray400),
        ProfileItemCard(
          title: 'Seguridad',
          subtitle: 'PIN, biometría y autenticación',
          icon: Symbols.shield_lock,
        ),
      ],
    );
  }
}

class _BuildSupportSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            'Soporte',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.gray600,
            ),
          ),
        ),
        const SizedBox(height: 15),
        ProfileItemCard(
          title: 'Centro de Ayuda',
          subtitle: 'Preguntas frecuentes y guía',
          icon: Symbols.question_mark,
        ),
        const Divider(color: AppColors.gray400),
        ProfileItemCard(
          title: 'Contactar Soporte',
          subtitle: 'Chat y tickets',
          icon: Symbols.question_answer,
        ),
        const Divider(color: AppColors.gray400),
        ProfileItemCard(
          title: 'Llamar a Soporte',
          subtitle: '+52 800 123 4567',
          icon: Symbols.phone,
        ),
      ],
    );
  }
}

class _BuildLegalSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            'Legal',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.gray600,
            ),
          ),
        ),
        const SizedBox(height: 15),
        ProfileItemCard(
          title: 'Términos y condiciones',
          subtitle: 'Condiciones de uso de servicio',
          icon: Symbols.list_alt,
        ),
        const Divider(color: AppColors.gray400),
        ProfileItemCard(
          title: 'Política de Privacidad',
          subtitle: 'Manejo de datos personales',
          icon: Symbols.lock,
        ),
        const Divider(color: AppColors.gray400),
        ProfileItemCard(
          title: 'Aviso Legal',
          subtitle: 'Información Regulatoria',
          icon: Symbols.handyman,
        ),
      ],
    );
  }
}

class _BuildAppSection extends StatefulWidget {
  @override
  State<_BuildAppSection> createState() => _BuildAppSectionState();
}

class _BuildAppSectionState extends State<_BuildAppSection> {
  String version = 'Desconocida';

  @override
  void initState() {
    getAppVersion();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            'Aplicación',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.gray600,
            ),
          ),
        ),
        const SizedBox(height: 15),
        ProfileItemCard(
          title: 'Calificar App',
          subtitle: 'Ayúdanos a mejorar',
          icon: Symbols.star,
        ),
        const Divider(color: AppColors.gray400),
        ProfileItemCard(
          title: 'Compartir App',
          subtitle: 'Invita a tus amigos',
          icon: Symbols.share,
        ),
        const Divider(color: AppColors.gray400),
        ProfileItemCard(
          title: 'Versión',
          subtitle: version,
          icon: Symbols.exclamation,
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

      print('Version: $version');
    } catch (e) {
      version = 'Desconocida';
    }
  }
}

class ProfileItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const ProfileItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 15,
        ),
        onTap: () {},
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.greenLight,
              ),
              child: Icon(icon, size: 28, color: AppColors.gray700),
            ),
            SizedBox(width: 15),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.gray600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
