import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:makerslab_app/core/entities/material.dart';
import 'package:makerslab_app/core/entities/module.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../shared/widgets/index.dart';
import '../../../../core/entities/instruction.dart';
import '../../../../theme/app_color.dart';
import '../../../home/presentation/pages/home_page.dart';
import 'instruction_detail_page.dart';

class TemperaturePage extends StatelessWidget {
  static const String routeName = '/temperature';
  const TemperaturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          MainSliverBackAppBar(
            assetImagePath: 'assets/images/static/esp32TempSensor.webp',
            centerTitle: true,
            backLabel: 'DHT11 Temperatura',
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),
              _BuildMainContent(),
            ]),
          ),
        ],
      ),
    );
  }
}

class _BuildMainContent extends StatelessWidget {
  final MainModule mainModule = MainModule(
    title: 'title',
    description: 'description',
    image: 'assets/images/static/esp32-dht11.jpg',
    instructions: [
      Instruction(
        title: 'Instrucción 1',
        description: 'Descripción de la instrucción 1',
        actionType: IntructionType.internalRoute,
        actionValue: '/ruta-interna-1',
      ),
      Instruction(
        title: 'Instrucción 2',
        description: 'Descripción de la instrucción 2',
        actionType: IntructionType.externalUrl,
        actionValue: 'https://example.com',
      ),
      Instruction(
        title: 'Instrucción 3',
        description: 'Descripción de la instrucción 3',
        actionType: IntructionType.none,
      ),
    ],
    materials: [
      MaterialItem(
        title: 'Microcontrolador ESP32',
        description: '1 unidad',
        actionType: MaterialItemType.internalRoute,
        actionValue: '/ruta-interna-1',
      ),
      MaterialItem(
        title: 'Sensor DHT11',
        description: '1 unidad',
        actionType: MaterialItemType.internalRoute,
        actionValue: 'ruta-interna-1',
      ),
      MaterialItem(
        title: 'Resistencia 10k',
        description: '1 unidad',
        actionType: MaterialItemType.internalRoute,
        actionValue: '/ruta-interna-1',
      ),
      MaterialItem(
        title: 'Cables de conexión',
        description: '20 unidades',
        actionType: MaterialItemType.internalRoute,
        actionValue: '/ruta-interna-1',
      ),
      MaterialItem(
        title: 'Protoboard',
        description: '1 unidad',
        actionType: MaterialItemType.internalRoute,
        actionValue: '/ruta-interna-1',
      ),
      MaterialItem(
        title: 'Fuente de alimentación',
        description: '1 unidad',
        actionType: MaterialItemType.internalRoute,
        actionValue: '/ruta-interna-1',
      ),
      MaterialItem(
        title: 'Software de programación',
        description: 'Instalar Arduino IDE',
        actionType: MaterialItemType.externalUrl,
        actionValue: 'https://www.arduino.cc/es/software',
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Aquí iría el contenido real de la pantalla
        _InstructionsSection(instructions: mainModule.instructions ?? []),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: YouTubePlayer(videoId: 'K98h51XuqBE'),
        ),
        const SizedBox(height: 30),
        _BillOfMaterialsSection(materials: mainModule.materials ?? []),
        const SizedBox(height: 800), // Solo para probar el scroll
      ],
    );
  }
}

class _InstructionsSection extends StatelessWidget {
  final List<Instruction> instructions;
  const _InstructionsSection({required this.instructions});

  @override
  Widget build(BuildContext context) {
    List<Color> buildGradientFromColor(Color base) {
      return [base, Color.alphaBlend(AppColors.black.withOpacity(0.1), base)];
    }

    return PxGenericListSection(
      title: 'Instrucciones',
      onViewAll:
          () => context.push(
            '/temperature/instruction_details',
            extra: instructions,
          ),
      onViewAllLabel: 'Ver todos',
      items: instructions,
      height: 180,
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, item) {
        return AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: buildGradientFromColor(AppColors.primary),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    item.description,
                    style: const TextStyle(color: AppColors.white),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => onItemTap(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    foregroundColor: AppColors.primary,
                    backgroundColor: AppColors.white,
                  ),
                  child: const Text('Ver más'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> onItemTap(BuildContext context) async {}
}

class _BillOfMaterialsSection extends StatelessWidget {
  final List<MaterialItem> materials;
  const _BillOfMaterialsSection({required this.materials});

  @override
  Widget build(BuildContext context) {
    return PxGenericListSection(
      title: 'Materiales',
      onViewAll: () {},
      items: materials,
      height: 180,
      scrollDirection: Axis.vertical,
      itemBuilder: (context, item) {
        return ListTile(
          onTap: () => onItemTap(item, context),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gray300,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Icon(Icons.check, color: AppColors.primary),
          ),
          title: Text(item.title),
          subtitle: Text(item.description),
        );
      },
    );
  }

  Future<void> onItemTap(MaterialItem item, BuildContext context) async {
    switch (item.actionType) {
      case MaterialItemType.internalRoute:
        if (item.actionValue != null) {
          context.push(item.actionValue ?? HomePage.routeName);
        }
        break;
      case MaterialItemType.externalUrl:
        if (item.actionValue != null) {
          await launchUrl(
            Uri.parse(item.actionValue!),
            mode: LaunchMode.externalApplication,
          );
        }
        break;
      case MaterialItemType.none:
        // No hace nada o muestra mensaje
        break;
    }
  }
}
