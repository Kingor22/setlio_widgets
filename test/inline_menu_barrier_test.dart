import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setlio_widgets/setlio_widgets.dart';

/// Nutzer-Vorgabe 11.08.: „Jeder Tipp auf dem Bildschirm schließt
/// zuerst." Solange ein Inline-Menü offen ist, liegt ein Fänger über der
/// ganzen Fläche — ein Tipp irgendwo schließt das Menü und löst sonst
/// NICHTS aus. Nur die Zeile mit dem offenen Menü bleibt bedienbar,
/// sonst käme man an die Optionen nicht heran.
void main() {
  late InlineMenuController menu;

  Widget host({required VoidCallback aussen, required VoidCallback chip}) =>
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              // Etwas ganz anderes auf dem Bildschirm — die
              // Metronom-Steuerung, die Kopfzeile, was auch immer.
              SizedBox(
                height: 120,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: aussen,
                  child: const Center(child: Text('woanders')),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    Builder(
                      builder: (itemContext) => AnimatedBuilder(
                        animation: menu,
                        builder: (context, _) => GestureDetector(
                          onLongPress: () => menu.toggle(
                            'zeile',
                            itemContext: itemContext,
                            scrollController: null,
                            sectionHeight: 0,
                          ),
                          child: GrowVeil(
                            animation: menu.animation,
                            label: 'Ersetzen',
                            icon: Icons.find_replace,
                            onTap: chip,
                            child: const SizedBox(
                              height: 72,
                              width: double.infinity,
                              child: Center(child: Text('Zeile')),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  testWidgets('offenes Menü: Tipp woanders schließt nur', (tester) async {
    var aussen = 0;
    var chip = 0;
    menu = InlineMenuController(vsync: tester);
    addTearDown(menu.dispose);

    await tester.pumpWidget(host(aussen: () => aussen++, chip: () => chip++));
    await tester.longPress(find.text('Zeile'));
    await tester.pumpAndSettle();
    expect(menu.hasOpenMenu, isTrue);

    await tester.tap(find.text('woanders'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(aussen, 0, reason: 'der erste Tipp gehoert dem Schliessen');
    expect(menu.hasOpenMenu, isFalse);

    // Der ZWEITE Tipp wirkt wieder ganz normal.
    await tester.tap(find.text('woanders'));
    await tester.pumpAndSettle();
    expect(aussen, 1);
    expect(chip, 0);
  });

  testWidgets('das Menü selbst bleibt erreichbar', (tester) async {
    var aussen = 0;
    var chip = 0;
    menu = InlineMenuController(vsync: tester);
    addTearDown(menu.dispose);

    await tester.pumpWidget(host(aussen: () => aussen++, chip: () => chip++));
    await tester.longPress(find.text('Zeile'));
    await tester.pumpAndSettle();

    // Das Loch im Fänger liegt genau über der gehaltenen Zeile.
    await tester.tap(find.text('Ersetzen'));
    await tester.pumpAndSettle();
    expect(chip, 1, reason: 'die Chips duerfen nicht abgefangen werden');
    expect(aussen, 0);
  });
}
