import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setlio_widgets/setlio_widgets.dart';

/// Der ganze Zweck dieser Komponente ist, dass ein Wisch NICHT löscht.
/// Wenn sich das je ändert, verliert jemand seine Songs — deshalb steht
/// es hier so ausführlich fest.
void main() {
  Widget host(List<String> items, void Function(String) onDelete) {
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            for (final item in items)
              SwipeRevealDelete(
                itemKey: item,
                enabled: true,
                onDelete: () => onDelete(item),
                child: SizedBox(
                  height: 60,
                  child: Center(child: Text(item)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  testWidgets('Wischen allein löscht nichts', (tester) async {
    final deleted = <String>[];
    await tester.pumpWidget(host(['Song A'], deleted.add));

    await tester.drag(find.text('Song A'), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(deleted, isEmpty, reason: 'ein voller Zug darf nie löschen');
    expect(find.text('Song A'), findsOneWidget);
  });

  testWidgets('Wischen legt das Löschfeld frei, Tippen löscht', (tester) async {
    final deleted = <String>[];
    await tester.pumpWidget(host(['Song A'], deleted.add));

    expect(find.text('Löschen'), findsNothing);

    await tester.drag(find.text('Song A'), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(find.text('Löschen'), findsOneWidget);
    expect(deleted, isEmpty, reason: 'offen heisst noch nicht gelöscht');

    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();
    expect(deleted, ['Song A']);
  });

  testWidgets('das Löschfeld ist nur so breit wie freigelegt (SET-76)', (
    tester,
  ) async {
    // Nutzer-Befund 21.08.: Der rote Block stand sofort in voller Breite
    // hinter der Zeile und schimmerte bei jedem Pixel Versatz und an den
    // runden Ecken durch. Jetzt waechst die Flaeche mit dem Finger.
    await tester.pumpWidget(host(['Song A'], (_) {}));

    final geste = await tester.startGesture(
      tester.getCenter(find.text('Song A')),
    );
    // Der Clip direkt um die Loesch-Aktion — nicht irgendein ClipRect
    // weiter oben im Baum (Scaffold & Co. haben eigene).
    Finder clip() => find
        .ancestor(of: find.text('Löschen'), matching: find.byType(ClipRect))
        .first;

    await geste.moveBy(const Offset(-50, 0));
    await tester.pump();
    final teilweise = tester.getSize(clip()).width;
    expect(teilweise, greaterThan(0));

    await geste.moveBy(const Offset(-300, 0));
    await geste.up();
    await tester.pumpAndSettle();
    final voll = tester.getSize(clip()).width;

    expect(
      teilweise,
      lessThan(voll * 0.7),
      reason: 'halb gewischt darf nicht die ganze Flaeche zeigen',
    );
  });

  testWidgets('kurzer Wisch schnappt zurück', (tester) async {
    final deleted = <String>[];
    await tester.pumpWidget(host(['Song A'], deleted.add));

    // Unter der halben Strecke, ohne Schwung.
    await tester.timedDrag(
      find.text('Song A'),
      const Offset(-20, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();

    expect(find.text('Löschen'), findsNothing);
    expect(deleted, isEmpty);
  });

  testWidgets('Tippen auf die Zeile schliesst nur', (tester) async {
    final deleted = <String>[];
    await tester.pumpWidget(host(['Song A'], deleted.add));

    await tester.drag(find.text('Song A'), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(find.text('Löschen'), findsOneWidget);

    await tester.tap(find.text('Song A'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Löschen'), findsNothing);
    expect(deleted, isEmpty);
  });

  testWidgets('nur eine Zeile ist gleichzeitig offen', (tester) async {
    final deleted = <String>[];
    await tester.pumpWidget(host(['Song A', 'Song B'], deleted.add));

    await tester.drag(find.text('Song A'), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(find.text('Löschen'), findsOneWidget);

    await tester.drag(find.text('Song B'), const Offset(-120, 0));
    await tester.pumpAndSettle();

    expect(
      find.text('Löschen'),
      findsOneWidget,
      reason: 'sonst stünden mehrere scharfe Löschfelder herum',
    );
    expect(deleted, isEmpty);
  });

  testWidgets('abgeschaltet lässt sich gar nicht wischen', (tester) async {
    final deleted = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwipeRevealDelete(
            itemKey: 'a',
            enabled: false,
            onDelete: () => deleted.add('a'),
            child: const SizedBox(
              height: 60,
              child: Center(child: Text('Song A')),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.text('Song A'), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Löschen'), findsNothing);
    expect(deleted, isEmpty);
  });

  group('zweite Aktion nach rechts', () {
    Widget hostBoth({
      required VoidCallback onDelete,
      required VoidCallback onLeading,
    }) =>
        MaterialApp(
          home: Scaffold(
            body: SwipeRevealDelete(
              itemKey: 'a',
              enabled: true,
              onDelete: onDelete,
              leadingLabel: 'In Ordner',
              leadingIcon: Icons.folder_outlined,
              onLeading: onLeading,
              child: const SizedBox(
                height: 60,
                child: Center(child: Text('Song A')),
              ),
            ),
          ),
        );

    testWidgets('nach rechts legt sie frei, Tippen löst aus', (tester) async {
      var deleted = 0;
      var moved = 0;
      await tester.pumpWidget(
        hostBoth(onDelete: () => deleted++, onLeading: () => moved++),
      );

      await tester.drag(find.text('Song A'), const Offset(120, 0));
      await tester.pumpAndSettle();
      expect(find.text('In Ordner'), findsOneWidget);
      expect(find.text('Löschen'), findsNothing);
      expect(moved, 0, reason: 'auch hier löst erst der Tipp aus');

      await tester.tap(find.text('In Ordner'));
      await tester.pumpAndSettle();
      expect(moved, 1);
      expect(deleted, 0);
    });

    testWidgets('ohne zweite Aktion geht nur nach links', (tester) async {
      var deleted = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeRevealDelete(
              itemKey: 'a',
              enabled: true,
              onDelete: () => deleted++,
              child: const SizedBox(
                height: 60,
                child: Center(child: Text('Song A')),
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.text('Song A'), const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(find.text('Löschen'), findsNothing);
      expect(deleted, 0);
    });
  });

  group('eine Geste, ein Schritt', () {
    Widget hostBoth(List<String> log) => MaterialApp(
          home: Scaffold(
            body: SwipeRevealDelete(
              itemKey: 'a',
              enabled: true,
              onDelete: () => log.add('delete'),
              leadingLabel: 'In Ordner',
              leadingIcon: Icons.folder_outlined,
              onLeading: () => log.add('folder'),
              child: const SizedBox(
                height: 60,
                child: Center(child: Text('Song A')),
              ),
            ),
          ),
        );

    testWidgets(
        'aus dem offenen Löschfeld führt ein Wisch nach rechts '
        'zurück auf neutral — nicht weiter zum Ordner', (tester) async {
      final log = <String>[];
      await tester.pumpWidget(hostBoth(log));

      await tester.drag(find.text('Song A'), const Offset(-120, 0));
      await tester.pumpAndSettle();
      expect(find.text('Löschen'), findsOneWidget);

      // Derselbe Zug zurück: früher lief der Controller bis an seine
      // untere Grenze durch und legte die Ordner-Aktion frei — man kam
      // aus der Ansicht gar nicht mehr heraus.
      await tester.drag(
        find.text('Song A'),
        const Offset(200, 0),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('Löschen'), findsNothing);
      expect(find.text('In Ordner'), findsNothing,
          reason: 'neutral, nicht Ordner');
      expect(log, isEmpty);
    });

    testWidgets('erst der zweite Wisch nach rechts zeigt den Ordner', (
      tester,
    ) async {
      final log = <String>[];
      await tester.pumpWidget(hostBoth(log));

      await tester.drag(find.text('Song A'), const Offset(-120, 0));
      await tester.pumpAndSettle();
      await tester.drag(
        find.text('Song A'),
        const Offset(200, 0),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(find.text('In Ordner'), findsNothing);

      await tester.drag(find.text('Song A'), const Offset(120, 0));
      await tester.pumpAndSettle();
      expect(find.text('In Ordner'), findsOneWidget);
      expect(log, isEmpty);
    });

    testWidgets('aus dem offenen Ordner führt ein Wisch nach links zurück', (
      tester,
    ) async {
      final log = <String>[];
      await tester.pumpWidget(hostBoth(log));

      await tester.drag(find.text('Song A'), const Offset(120, 0));
      await tester.pumpAndSettle();
      expect(find.text('In Ordner'), findsOneWidget);

      await tester.drag(
        find.text('Song A'),
        const Offset(-200, 0),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(find.text('In Ordner'), findsNothing);
      expect(find.text('Löschen'), findsNothing);
      expect(log, isEmpty);
    });
  });
}
