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
}
