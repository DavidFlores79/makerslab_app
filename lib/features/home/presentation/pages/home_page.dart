import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/entities/main_menu_item.dart';
import '../../../../shared/widgets/index.dart';
import '../../../../theme/app_color.dart';
import '../../../../utils/formatters.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

class HomePage extends StatefulWidget {
  static const String routeName = "/home";
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
              final List<MainMenuItem> menu = state.mainMenuItems ?? [];

              return Scrollbar(
                thickness: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 20,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: menu.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                childAspectRatio: 1,
                                crossAxisCount: 2,
                                crossAxisSpacing: 10.0,
                                mainAxisSpacing: 10.0,
                              ),
                          itemBuilder: (BuildContext context, int index) {
                            return Card(
                              color: AppColors.gray300,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: InkWell(
                                onTap: () => context.push(menu[index].route),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Icon(
                                        menu[index].icon,
                                        size: 50,
                                        color: menu[index].iconColor,
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        menu[index].title,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.black3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
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
                child: MainAppButton(
                  label: 'Depositar',
                  onPressed: () {},
                  expand: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MainAppButton(
                  label: 'Invertir',
                  variant: ButtonVariant.outlined,
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
