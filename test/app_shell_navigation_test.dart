import 'package:atelierpro_mobile/screens/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('selects the detail branch and preserves tab state',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/clients',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => AppShell(
            navigationShell: navigationShell,
            connectivityBanner: const SizedBox.shrink(),
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Atelier home')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/clients',
                  builder: (context, state) => Scaffold(
                    body: Column(
                      children: [
                        const TextField(
                          key: Key('client-search'),
                          decoration: InputDecoration(labelText: 'Recherche'),
                        ),
                        TextButton(
                          onPressed: () => context.push('/clients/client-1'),
                          child: const Text('Ouvrir client'),
                        ),
                      ],
                    ),
                  ),
                  routes: [
                    GoRoute(
                      path: ':clientId',
                      builder: (context, state) => const Scaffold(
                        body: Text('Détail client'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/commandes',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Commandes')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/mesures',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Fiches')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/parametres',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Réglages')),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('client-search')), 'Aïssa');
    await tester.tap(find.text('Commandes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clients'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Aïssa',
    );

    await tester.tap(find.text('Ouvrir client'));
    await tester.pumpAndSettle();
    expect(find.text('Détail client'), findsOneWidget);
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1);
  });
}
