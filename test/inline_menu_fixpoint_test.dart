import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setlio_widgets/setlio_widgets.dart';

/// SET-52: Beim Öffnen des Inline-Menüs bleibt die gehaltene Zeile der
/// Fixpunkt — auch in Lazy-Listen mit stark unterschiedlichen
/// Zeilenhöhen (aufgeklappte Medleys), deren Geometrie der Sliver
/// abseits des Viewports nur schätzt.
void main() {
  const sectionHeight = 46.0;
  const rowKey = Key('row-20');

  late InlineMenuController menu;

  Widget host(TickerProvider vsync, ScrollController scroll) {
    return MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            menu.removeListener(() {});
            return ListenableBuilder(
              listenable: menu,
              builder: (context, _) => ListView.builder(
                controller: scroll,
                itemCount: 60,
                itemBuilder: (context, index) {
                  // Jede 7. Zeile ist ein „aufgeklapptes Medley":
                  // dreimal so hoch — die Extent-Schätzung der Liste
                  // liegt damit garantiert daneben.
                  final tall = index % 7 == 0;
                  final id = 'row-$index';
                  final open = menu.isOpen(id);
                  return Builder(
                    builder: (itemContext) => Column(
                      children: [
                        if (open)
                          GrowSection(
                            animation: menu.animation,
                            above: true,
                            height: sectionHeight,
                            child: const Text('oben'),
                          ),
                        GestureDetector(
                          key: index == 20 ? rowKey : null,
                          onLongPress: () => menu.toggle(
                            id,
                            itemContext: itemContext,
                            scrollController: scroll,
                            sectionHeight: sectionHeight,
                          ),
                          child: Container(
                            height: tall ? 180 : 60,
                            color: tall
                                ? Colors.blueGrey.shade700
                                : Colors.grey.shade800,
                            child: Text('Zeile $index'),
                          ),
                        ),
                        if (open)
                          GrowSection(
                            animation: menu.animation,
                            above: false,
                            height: sectionHeight,
                            child: const Text('unten'),
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  testWidgets('gehaltene Zeile bleibt beim Öffnen exakt stehen', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    menu = InlineMenuController(vsync: tester);
    addTearDown(menu.dispose);

    await tester.pumpWidget(host(tester, scroll));
    // In die Listenmitte scrollen (mehrere hohe Zeilen über uns —
    // die Schätzfehler-Situation aus dem Bug).
    scroll.jumpTo(1200);
    await tester.pump();

    final before = tester.getTopLeft(find.byKey(rowKey)).dy;
    await tester.longPress(find.byKey(rowKey));
    await tester.pumpAndSettle();

    final after = tester.getTopLeft(find.byKey(rowKey)).dy;
    expect(
      (after - before).abs(),
      lessThan(2.0),
      reason: 'Fixpunkt: gehaltene Zeile darf beim Menü-Öffnen nicht '
          'springen (vorher $before, nachher $after)',
    );

    // Schließen: Zeile bleibt wieder stehen.
    menu.close(scrollController: scroll);
    await tester.pumpAndSettle();
    final closed = tester.getTopLeft(find.byKey(rowKey)).dy;
    expect((closed - after).abs(), lessThan(2.0));
  });
}
