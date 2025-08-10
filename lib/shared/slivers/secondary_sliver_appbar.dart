import 'package:flutter/material.dart';

import '../../theme/app_color.dart';

class SecondarySliverAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String?
  backgroundImage; // ruta asset o url de red (si empieza por http)
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final double expandedHeight;
  final Color beginGradient;
  final Color endGradient;

  const SecondarySliverAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.backgroundImage,
    this.actions,
    this.onBack,
    this.expandedHeight = 160,
    this.beginGradient = AppColors.primary,
    this.endGradient = AppColors.primary,
  });

  bool _isNetworkImage(String? path) => path != null && path.startsWith('http');

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: _BackCircleButton(
          onTap: onBack ?? () => Navigator.of(context).pop(),
        ),
      ),
      actions: actions,
      expandedHeight: expandedHeight,
      // Usamos LayoutBuilder dentro de flexibleSpace para detectar el estado
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double max = expandedHeight;
          final double min = kToolbarHeight;
          final double curr = constraints.maxHeight.clamp(min, max);
          final double t = ((curr - min) / (max - min)).clamp(0.0, 1.0);
          // t: 1 -> fully expanded, 0 -> collapsed

          // Colores del título: blanco en expandido, negro al colapsar
          final Color titleColor = Color.lerp(Colors.black87, Colors.white, t)!;
          final Color subtitleColor = Colors.white.withOpacity(0.9);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Fondo: imagen (network/asset) o gradiente
              if (backgroundImage != null)
                _isNetworkImage(backgroundImage)
                    ? Image.network(backgroundImage!, fit: BoxFit.cover)
                    : Image.asset(backgroundImage!, fit: BoxFit.cover)
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [beginGradient, endGradient],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

              // Overlay para mejorar contraste cuando esté expandido
              Container(
                color: Colors.black.withOpacity(
                  0.18 * t,
                ), // más oscuro al expandir
              ),

              // Contenido del flexible space: título/subtítulo
              // Alineamos al bottomLeft para que el título quede "pegado abajo"
              Padding(
                padding: EdgeInsets.only(
                  left: 16 + 48, // deja espacio para el back circular
                  right: 16,
                  bottom: 12,
                  top: MediaQuery.of(context).padding.top,
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle: aparece solo cuando expandido (opacidad ligada a t)
                      if (subtitle != null)
                        Opacity(
                          opacity: t,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Text(
                              subtitle!,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                      // Title: escala ligeramente y cambia color
                      Transform.translate(
                        offset: Offset(0, (1 - t) * 2), // pequeño lift effect
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            shadows:
                                t > 0.5
                                    ? [
                                      const Shadow(
                                        color: Colors.black38,
                                        offset: Offset(0, 1),
                                        blurRadius: 4,
                                      ),
                                    ]
                                    : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // separador sutil cuando está colapsado
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.black12),
      ),
    );
  }
}

class _BackCircleButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackCircleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.white, // botón blanco
        elevation: 2,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(10.0),
            child: Icon(Icons.arrow_back, size: 24, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}
