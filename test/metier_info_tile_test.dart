import 'package:atelierpro_mobile/screens/settings/widgets/metier_info_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the trade as plain, non-interactive information',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MetierInfoTile(metier: 'Couture / Confection'),
        ),
      ),
    );

    expect(find.text('Métier'), findsOneWidget);
    expect(find.text('Couture / Confection'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    expect(find.byType(InkWell), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });
}
