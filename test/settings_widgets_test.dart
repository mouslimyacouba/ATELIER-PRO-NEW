import 'package:atelierpro_mobile/screens/settings/widgets/settings_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _host(ThemeData theme, Widget child, {double width = 360}) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  for (final entry in {
    'clair': ThemeData.light(),
    'sombre': ThemeData.dark(),
  }.entries) {
    group('SettingsGroup / SettingsRow en thème ${entry.key}', () {
      testWidgets('affiche titre et sous-titre, et réagit au toucher',
          (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          _host(
            entry.value,
            SettingsGroup(
              children: [
                SettingsRow(
                  icon: Icons.settings_outlined,
                  title: 'Paramètres',
                  subtitle: 'Thème et notifications',
                  onTap: () => taps++,
                ),
              ],
            ),
          ),
        );

        expect(find.text('Paramètres'), findsOneWidget);
        expect(find.text('Thème et notifications'), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);

        await tester.tap(find.text('Paramètres'));
        expect(taps, 1);
      });

      testWidgets('une ligne sans action est une simple information',
          (tester) async {
        await tester.pumpWidget(
          _host(
            entry.value,
            const SettingsGroup(
              children: [
                SettingsRow(
                  icon: Icons.cloud_done_outlined,
                  title: 'Fonctionnement hors ligne',
                  subtitle: 'Vos saisies sont envoyées au retour du réseau.',
                ),
              ],
            ),
          ),
        );

        expect(find.byIcon(Icons.chevron_right), findsNothing);
      });

      testWidgets('les textes longs ne débordent pas en petit écran',
          (tester) async {
        await tester.pumpWidget(
          _host(
            entry.value,
            const SettingsGroup(
              children: [
                SettingsRow(
                  icon: Icons.notifications_outlined,
                  title: 'Rappels de livraison',
                  subtitle: 'La veille et le jour de la livraison, à 8 h, et '
                      'pour les commandes en retard.',
                ),
                SettingsRow(
                  icon: Icons.delete_outline,
                  title: 'Supprimer mon compte',
                  subtitle: 'Supprime votre compte et toutes vos données',
                  danger: true,
                ),
              ],
            ),
            width: 300,
          ),
        );

        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('les titres de section sont annoncés comme des en-têtes',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        ThemeData.light(),
        const SettingsSectionLabel('Mon atelier'),
      ),
    );

    expect(
      tester.getSemantics(find.text('MON ATELIER')),
      matchesSemantics(label: 'MON ATELIER', isHeader: true),
    );
    handle.dispose();
  });
}
