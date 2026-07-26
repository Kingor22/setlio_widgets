import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:setlio_shared/setlio_shared.dart';

/// Inline-Aufklapp-Menü für Listeneinträge (Songs, Medleys, Pausen, Sets,
/// Termine, Gigs) — gemeinsame Fassung für Setlio und Setronome.
///
/// Das Verhalten ist in allen Listen gleich: Der gehaltene Eintrag bleibt
/// exakt an seiner Stelle stehen, die Optionen wachsen ober- und unterhalb
/// aus seinen Kanten heraus, und die übrigen Einträge weichen dabei
/// animiert aus, statt überdeckt zu werden. Beim Schließen läuft dieselbe
/// Bewegung rückwärts.
///
/// Zwei Teile arbeiten dafür zusammen:
///   * [GrowSection] schafft den Platz ([SizeTransition] schiebt die Liste
///     auseinander),
///   * [computeGrowScrollDelta] gleicht die Scrollposition genau um diesen
///     Betrag aus, damit der gehaltene Eintrag nicht wandert.
/// [InlineMenuController] bündelt beides samt „nur ein Menü gleichzeitig".

/// Ein Options-Bereich, der aus einer Kante des gehaltenen Balkens wächst
/// ([above]: aus dessen Oberkante, sonst aus der Unterkante).
class GrowSection extends StatelessWidget {
  const GrowSection({
    super.key,
    required this.animation,
    required this.above,
    required this.height,
    required this.child,
  });

  final Animation<double> animation;
  final bool above;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Bewusst OHNE ScaleTransition: skalierter Text liegt zwischen dem
    // Pixelraster und verwischt während der Animation — Wachsen (Size)
    // plus Einblenden reicht für den Grow-Effekt und bleibt scharf.
    return SizeTransition(
      sizeFactor: animation,
      alignment: above ? Alignment.bottomCenter : Alignment.topCenter,
      child: FadeTransition(
        opacity: animation,
        child: SizedBox(height: height, child: child),
      ),
    );
  }
}

/// Schleier über dem gehaltenen Balken: Akzent-Umrandung + Aktions-Chip
/// in der Mitte — der Balken selbst bleibt in Position und Größe stabil.
class GrowVeil extends StatelessWidget {
  const GrowVeil({
    super.key,
    required this.animation,
    required this.onTap,
    required this.label,
    required this.icon,
    required this.child,
    this.chipKey,
    this.enabled = true,
    this.borderRadius = DesignTokens.radiusButton,
  });

  final Animation<double> animation;
  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final Widget child;
  final Key? chipKey;

  /// false: Rechte fehlen — Chip ausgegraut; [onTap] bleibt verdrahtet
  /// (der Aufrufer entscheidet, z. B. Menü nur schließen).
  final bool enabled;

  /// Muss zum Radius der Listenzeile passen, damit der Schleier bündig
  /// aufliegt (Setlio: Buttons/Felder, Setronome: Karten).
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final accent = enabled
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).disabledColor;
    final surface = Theme.of(context).colorScheme.surface;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: FadeTransition(
            opacity: animation,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(color: accent, width: 1.5),
                  color: accent.withValues(alpha: 0.08),
                ),
                child: Center(
                  child: DecoratedBox(
                    key: chipKey,
                    decoration: BoxDecoration(
                      color: surface.withValues(alpha: 0.92),
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                      border: Border.all(color: accent, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 16, color: accent),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(color: accent, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Options-Schaltfläche der Grow-Bereiche. [onTap] null = ausgegraut
/// (keine Bearbeitungsrechte).
class GrowOptionButton extends StatelessWidget {
  const GrowOptionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

/// Scroll-Weg beim Öffnen: Ideal bleibt der gehaltene Balken exakt
/// stehen (Scroll += eine Bereichshöhe — die Liste darüber rückt hoch,
/// darunter runter); an den Rändern wird so verschoben, dass das
/// komplette Menü sichtbar ist (erster Eintrag: alles rückt nach unten,
/// letzter: alles nach oben). [sectionHeight] = Höhe EINES Bereichs
/// (oben und unten gleich hoch).
double computeGrowScrollDelta({
  required RenderObject? box,
  required ScrollPosition position,
  required double sectionHeight,
}) {
  if (box is! RenderBox) return 0;
  final viewport = RenderAbstractViewport.maybeOf(box);
  if (viewport == null) return 0;
  final itemTop = viewport.getOffsetToReveal(box, 0).offset;
  final y0 = itemTop - position.pixels;
  final rowH = box.size.height;
  final h = position.viewportDimension;
  final maxAfter = position.maxScrollExtent + 2 * sectionHeight;
  final lower = math.max(y0 + rowH + 2 * sectionHeight - h, -position.pixels);
  final upper = math.min(y0, maxAfter - position.pixels);
  return lower > upper ? lower : sectionHeight.clamp(lower, upper).toDouble();
}

/// Verwaltet ein Inline-Menü über eine ganze Liste hinweg: welcher
/// Eintrag offen ist, die Auf-/Zu-Animation und den Scroll-Ausgleich,
/// der den gehaltenen Eintrag an Ort und Stelle hält.
///
/// Es ist immer höchstens EIN Menü offen: Wird bei geöffnetem Menü ein
/// anderer Eintrag gehalten, schließt das alte zuerst sauber und das neue
/// öffnet danach — kein Sprung, keine zwei gleichzeitig.
///
/// Der Controller ist ein [ChangeNotifier]; die Liste umschließt sich mit
/// einem [ListenableBuilder] (oder ruft `setState` im Listener). Bewusst
/// ohne Riverpod, damit beide Apps ihn unverändert nutzen können.
class InlineMenuController extends ChangeNotifier {
  InlineMenuController({
    required TickerProvider vsync,
    this.duration = const Duration(milliseconds: 200),
  }) : _controller = AnimationController(vsync: vsync, duration: duration) {
    animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  final Duration duration;
  final AnimationController _controller;

  /// Für [GrowSection] und [GrowVeil].
  late final CurvedAnimation animation;

  String? _openId;
  double _scrollDelta = 0;

  // Gemerkter Wunsch, während das vorherige Menü noch zufährt.
  String? _pendingId;
  BuildContext? _pendingContext;
  ScrollController? _pendingScroll;
  double _pendingSectionHeight = 0;

  /// Eintrag, dessen Menü gerade offen ist (null = keins).
  String? get openId => _openId;

  bool isOpen(String id) => _openId == id;

  bool get hasOpenMenu => _openId != null;

  /// Öffnet das Menü für [id]. [itemContext] ist der Kontext der
  /// Listenzeile — daraus wird ihre Lage im Viewport bestimmt, um den
  /// Scroll so auszugleichen, dass die Zeile stehen bleibt.
  void open(
    String id, {
    required BuildContext itemContext,
    required ScrollController? scrollController,
    required double sectionHeight,
  }) {
    final position = (scrollController?.hasClients ?? false)
        ? scrollController!.position
        : null;
    final delta = position == null
        ? 0.0
        : computeGrowScrollDelta(
            box: itemContext.findRenderObject(),
            position: position,
            sectionHeight: sectionHeight,
          );
    _openId = id;
    _scrollDelta = delta;
    notifyListeners();
    _controller.forward(from: 0);
    if (position != null && delta.abs() > 0.5) {
      scrollController!.animateTo(
        (position.pixels + delta).clamp(0.0, double.infinity),
        duration: duration,
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Schließt das offene Menü und fährt den Scroll-Ausgleich zurück.
  void close({ScrollController? scrollController}) {
    if (_openId == null) return;
    final delta = _scrollDelta;
    _scrollDelta = 0;
    if ((scrollController?.hasClients ?? false) && delta.abs() > 0.5) {
      scrollController!.animateTo(
        (scrollController.position.pixels - delta).clamp(0.0, double.infinity),
        duration: duration,
        curve: Curves.easeInCubic,
      );
    }
    _controller.reverse().whenComplete(() {
      _openId = null;
      notifyListeners();
      final id = _pendingId;
      final itemContext = _pendingContext;
      final pendingScroll = _pendingScroll;
      final sectionHeight = _pendingSectionHeight;
      _pendingId = null;
      _pendingContext = null;
      _pendingScroll = null;
      if (id == null || itemContext == null) return;
      // Erst im nächsten Frame: die Liste hat sich gerade
      // zusammengeschoben, vorher wäre die gemessene Lage veraltet.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!itemContext.mounted) return;
        open(
          id,
          itemContext: itemContext,
          scrollController: pendingScroll,
          sectionHeight: sectionHeight,
        );
      });
    });
  }

  /// Long-Press auf [id]: öffnet dessen Menü, schließt ein bereits
  /// offenes (auch dasselbe — dann wirkt der zweite Druck als Schließen).
  void toggle(
    String id, {
    required BuildContext itemContext,
    required ScrollController? scrollController,
    required double sectionHeight,
  }) {
    if (_openId == null) {
      open(
        id,
        itemContext: itemContext,
        scrollController: scrollController,
        sectionHeight: sectionHeight,
      );
      return;
    }
    if (_openId == id) {
      close(scrollController: scrollController);
      return;
    }
    // Anderer Eintrag: erst zufahren, dann den neuen öffnen.
    _pendingId = id;
    _pendingContext = itemContext;
    _pendingScroll = scrollController;
    _pendingSectionHeight = sectionHeight;
    if (_controller.status != AnimationStatus.reverse) {
      close(scrollController: scrollController);
    }
  }

  @override
  void dispose() {
    animation.dispose();
    _controller.dispose();
    super.dispose();
  }
}
