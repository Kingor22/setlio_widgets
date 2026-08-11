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

  // BUGFIX 11.08.: Der Schleier lag auch bei GESCHLOSSENEM Menue ueber
  // der Zeile — unsichtbar, aber undurchlaessig. Damit war jedes
  // Bedienelement im Balken tot: das + der Repertoire-Sidebar, der
  // Ziehgriff, das Gedrueckthalten einer Ordnerzeile.
  testWidgets('geschlossenes Menue: der Balken bleibt bedienbar', (
    tester,
  ) async {
    var kind = 0;
    var schleier = 0;
    var gehalten = 0;
    await tester.pumpWidget(
      host(
        GrowVeil(
          animation: const AlwaysStoppedAnimation(0),
          label: 'Laden',
          icon: Icons.play_arrow,
          onTap: () => schleier++,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: () => gehalten++,
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => kind++,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.add_circle_outline),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    expect(kind, 1, reason: 'das + gehoert dem Balken, nicht dem Schleier');
    expect(schleier, 0);

    await tester.longPress(find.byType(GrowVeil));
    expect(gehalten, 1, reason: 'Gedruecktes Halten muss durchkommen');
  });

  testWidgets('offenes Menue: der Schleier faengt wieder alles ab', (
    tester,
  ) async {
    var kind = 0;
    var schleier = 0;
    await tester.pumpWidget(
      host(
        GrowVeil(
          animation: const AlwaysStoppedAnimation(1),
          label: 'Laden',
          icon: Icons.play_arrow,
          onTap: () => schleier++,
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => kind++,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.add_circle_outline),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(
      tester.getTopRight(find.byType(GrowVeil)) + const Offset(-8, 8),
    );
    expect(kind, 0, reason: 'bei offenem Menue ist der Balken stillgelegt');
    expect(schleier, 1);
  });
}
