import 'package:atelierpro_mobile/core/theme.dart';
import 'package:atelierpro_mobile/providers/settings_provider.dart';
import 'package:atelierpro_mobile/providers/theme_provider.dart';
import 'package:atelierpro_mobile/screens/settings/app_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host({
  required ThemeProvider themeProvider,
  required SettingsProvider settingsProvider,
  required Widget child,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
    ],
    child: Consumer<ThemeProvider>(
      builder: (context, theme, _) => MaterialApp(
        theme: AtelierProTheme.light,
        darkTheme: AtelierProTheme.dark,
        themeMode: theme.themeMode,
        home: child,
      ),
    ),
  );
}

Future<(ThemeProvider, SettingsProvider)> _pump(
  WidgetTester tester, {
  Future<void> Function()? onNotificationsChanged,
}) async {
  SharedPreferences.setMockInitialValues({});
  final themeProvider = ThemeProvider();
  final settingsProvider = SettingsProvider();
  await tester.pumpWidget(
    _host(
      themeProvider: themeProvider,
      settingsProvider: settingsProvider,
      child: AppSettingsScreen(
        onNotificationsChanged: onNotificationsChanged,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (themeProvider, settingsProvider);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('affiche les choix de thème, les rappels et le hors-ligne',
      (tester) async {
    await _pump(tester, onNotificationsChanged: () async {});

    expect(find.text('Système'), findsOneWidget);
    expect(find.text('Clair'), findsOneWidget);
    expect(find.text('Sombre'), findsOneWidget);
    expect(find.text('Rappels de livraison'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Fonctionnement hors ligne'),
      200,
    );
    expect(find.text('Fonctionnement hors ligne'), findsOneWidget);
  });

  testWidgets('le choix de thème s’applique immédiatement et est restauré',
      (tester) async {
    final (themeProvider, _) =
        await _pump(tester, onNotificationsChanged: () async {});

    await tester.tap(find.text('Sombre'));
    await tester.pumpAndSettle();
    expect(themeProvider.themeMode, ThemeMode.dark);
    expect(find.text('Thème Sombre'), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('theme_mode'), ThemeMode.dark.index);

    late ThemeProvider restoredProvider;
    await tester.runAsync(() async {
      restoredProvider = ThemeProvider();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    expect(restoredProvider.themeMode, ThemeMode.dark);
  });

  testWidgets('le changement des rappels persiste et resynchronise',
      (tester) async {
    var syncs = 0;
    final (_, settingsProvider) = await _pump(
      tester,
      onNotificationsChanged: () async {
        syncs++;
      },
    );
    final before = settingsProvider.notificationsEnabled;

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(settingsProvider.notificationsEnabled, !before);
    expect(syncs, 1);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('notifications_enabled'), !before);
  });

  testWidgets('le bouton retour revient aux réglages', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final themeProvider = ThemeProvider();
    final settingsProvider = SettingsProvider();
    final router = GoRouter(
      initialLocation: '/parametres/preferences',
      routes: [
        GoRoute(
          path: '/parametres',
          builder: (context, state) => const Scaffold(
            body: Text('Accueil des réglages'),
          ),
        ),
        GoRoute(
          path: '/parametres/preferences',
          builder: (context, state) => AppSettingsScreen(
            onNotificationsChanged: () async {},
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<SettingsProvider>.value(
            value: settingsProvider,
          ),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, theme, _) => MaterialApp.router(
            theme: AtelierProTheme.light,
            darkTheme: AtelierProTheme.dark,
            themeMode: theme.themeMode,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();

    expect(find.text('Accueil des réglages'), findsOneWidget);
  });
}
