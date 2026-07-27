import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setlio_widgets/setlio_widgets.dart';

/// Der Schleier des Inline-Menüs trägt eine ODER zwei Aktionen
/// („ersetzen" / „bearbeiten"). Mit zwei Chips darf ein Tipp daneben
/// nichts auslösen — sonst wäre es Zufall, was man erwischt.
void main() {
  Widget host(Widget veil) => MaterialApp(
        home: Scaffold(
          body: Center(child: SizedBox(width: 380, height: 72, child: veil)),
        ),
      );

  testWidgets('eine Aktion: ganze Fläche löst aus', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        GrowVeil(
          animation: const AlwaysStoppedAnimation(1),
          label: 'Song ersetzen',
          icon: Icons.find_replace,
          onTap: () => taps++,
          child: const SizedBox.expand(),
        ),
      ),
    );
    expect(find.text('Song ersetzen'), findsOneWidget);
    // Ecke, weit weg vom Chip in der Mitte.
    await tester
        .tapAt(tester.getTopLeft(find.byType(GrowVeil)) + const Offset(8, 8));
    expect(taps, 1);
  });

  testWidgets('zwei Aktionen: nur die Chips lösen aus', (tester) async {
    var ersetzen = 0;
    var bearbeiten = 0;
    await tester.pumpWidget(
      host(
        GrowVeil(
          animation: const AlwaysStoppedAnimation(1),
          label: 'Medley ersetzen',
          icon: Icons.find_replace,
          onTap: () => ersetzen++,
          secondaryLabel: 'Medley bearbeiten',
          secondaryIcon: Icons.edit,
          secondaryOnTap: () => bearbeiten++,
          child: const SizedBox.expand(),
        ),
      ),
    );

    await tester
        .tapAt(tester.getTopLeft(find.byType(GrowVeil)) + const Offset(8, 8));
    expect(ersetzen, 0, reason: 'Tipp daneben darf nichts auslösen');
    expect(bearbeiten, 0);

    await tester.tap(find.text('Medley ersetzen'));
    expect(ersetzen, 1);
    expect(bearbeiten, 0);

    await tester.tap(find.text('Medley bearbeiten'));
    expect(ersetzen, 1);
    expect(bearbeiten, 1);
  });

  testWidgets('zwei Chips passen auf Telefonbreite', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 390 - 32,
              height: 72,
              child: GrowVeil(
                animation: const AlwaysStoppedAnimation(1),
                label: 'Medley ersetzen',
                icon: Icons.find_replace,
                onTap: () {},
                secondaryLabel: 'Medley bearbeiten',
                secondaryIcon: Icons.edit,
                secondaryOnTap: () {},
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
