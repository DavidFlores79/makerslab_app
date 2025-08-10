import 'package:flutter/material.dart';

import '../../../../core/entities/material.dart';
import '../../../../shared/widgets/index.dart';

class TemperatureMaterialDetailsPage extends StatelessWidget {
  static const String routeName = 'temperature/material_details';
  final List<MaterialItem> materials;
  const TemperatureMaterialDetailsPage({super.key, required this.materials});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          MainSliverBackAppBar(
            centerTitle: true,
            backLabel: 'Materials ${materials.length}',
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
  const _BuildMainContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Material  Details',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
