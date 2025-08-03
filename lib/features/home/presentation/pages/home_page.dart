import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/index.dart';
import '../../../../theme/app_color.dart';
import '../../../../utils/date_utils.dart';
import '../../../../utils/formatters.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    context.read<HomeBloc>().add(LoadHomeData());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PxMainAppBar(),
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state.status == HomeStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == HomeStatus.failure) {
              return Center(
                child: Text('Error: ${state.error ?? 'Algo salió mal'}'),
              );
            }
            if (state.status == HomeStatus.success) {
              final balance = state.balance!.amount;

              return Column(
                children: [
                  BalanceCard(balance: balance),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.gray200),
                      child: ListView(
                        padding: const EdgeInsets.all(15),
                        children: [
                          SectionHeader(
                            title: 'Remesas recibidas',
                            onViewAll: () {}, // navegar a lista completa
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox(); // estado inicial
          },
        ),
      ),
    );
  }
}

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.balance});
  final double balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Saldo disponible', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppFormatters.formatCurrency(balance),
                style: theme.textTheme.displayMedium,
              ),
              Text('MXN', style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: PXButton(
                  label: 'Depositar',
                  onPressed: () {},
                  expand: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PXButton(
                  label: 'Invertir',
                  variant: PXButtonVariant.outlined,
                  onPressed: () => context.go('/investments'),
                  expand: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onViewAll});
  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        if (onViewAll != null)
          TextButton(onPressed: onViewAll, child: const Text('Ver todas')),
      ],
    );
  }
}
