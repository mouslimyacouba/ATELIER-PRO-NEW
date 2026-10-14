import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/connectivity_banner.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    this.connectivityBanner = const ConnectivityBanner(),
  });

  final StatefulNavigationShell navigationShell;
  final Widget connectivityBanner;

  static const _tabs = [
    (Icons.storefront_outlined, Icons.storefront, 'Atelier'),
    (Icons.people_outline, Icons.people, 'Clients'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Commandes'),
    (Icons.description_outlined, Icons.description, 'Fiches'),
    (Icons.settings_outlined, Icons.settings, 'Réglages'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
        } else if (currentIndex != 0) {
          navigationShell.goBranch(0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              connectivityBanner,
              Expanded(child: navigationShell),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == currentIndex,
          ),
          destinations: [
            for (final tab in _tabs)
              NavigationDestination(
                icon: Icon(tab.$1),
                selectedIcon: Icon(tab.$2),
                label: tab.$3,
              ),
          ],
        ),
      ),
    );
  }
}
