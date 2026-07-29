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
    this.secondaryLabel,
    this.secondaryIcon,
    this.secondaryOnTap,
    this.secondaryChipKey,
    this.tertiaryLabel,
    this.tertiaryIcon,
    this.tertiaryOnTap,
    this.tertiaryChipKey,
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

  /// Zweite Aktion auf dem gehaltenen Balken, z. B. „bearbeiten" neben
  /// „ersetzen". Ohne diese Angaben verhält sich der Schleier exakt wie
  /// vorher: ein Chip, und die ganze Fläche löst ihn aus.
  ///
  /// Mit zweiter Aktion sind NUR die Chips antippbar – ein Tipp daneben
  /// tut nichts. Bei zwei gleichwertigen Möglichkeiten wäre es sonst
  /// Zufall, welche man auslöst.
  final String? secondaryLabel;
  final IconData? secondaryIcon;
  final VoidCallback? secondaryOnTap;
  final Key? secondaryChipKey;

  /// Optionale dritte Aktion (SET-UI: „Ins Metronom") — gleiche Regeln
  /// wie bei der zweiten: sobald mehr als ein Chip da ist, sind nur die
  /// Chips antippbar.
  final String? tertiaryLabel;
  final IconData? tertiaryIcon;
  final VoidCallback? tertiaryOnTap;
  final Key? tertiaryChipKey;

  @override
  Widget build(BuildContext context) {
    final accent = enabled
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).disabledColor;
    final surface = Theme.of(context).colorScheme.surface;
    final hasSecondary = secondaryLabel != null && secondaryIcon != null;
    final hasTertiary = tertiaryLabel != null && tertiaryIcon != null;
    final multi = hasSecondary || hasTertiary;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: FadeTransition(
            opacity: animation,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // Mit zwei Chips darf die Fläche nichts auslösen, sonst
              // wäre es Zufall, welche Aktion man erwischt.
              onTap: multi ? () {} : onTap,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(color: accent, width: 1.5),
                  color: accent.withValues(alpha: 0.08),
                ),
                child: Center(
                  // Zwei Chips („ersetzen" + „bearbeiten") sind auf
                  // schmalen Telefonen breiter als die Zeile. Lieber
                  // gemeinsam etwas kleiner skalieren als abschneiden —
                  // beide Beschriftungen müssen lesbar bleiben.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _chip(
                          key: chipKey,
                          icon: icon,
                          label: label,
                          accent: accent,
                          surface: surface,
                          // Ohne zweite Aktion fängt die ganze Fläche den
                          // Tipp – dann braucht der Chip keinen eigenen.
                          onTap: multi ? onTap : null,
                        ),
                        if (hasSecondary) ...[
                          const SizedBox(width: 8),
                          _chip(
                            key: secondaryChipKey,
                            icon: secondaryIcon!,
                            label: secondaryLabel!,
                            accent: accent,
                            surface: surface,
                            onTap: secondaryOnTap,
                          ),
                        ],
                        if (hasTertiary) ...[
                          const SizedBox(width: 8),
                          _chip(
                            key: tertiaryChipKey,
                            icon: tertiaryIcon!,
                            label: tertiaryLabel!,
                            accent: accent,
                            surface: surface,
                            onTap: tertiaryOnTap,
                          ),
                        ],
                      ],
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

Widget _chip({
  required Key? key,
  required IconData icon,
  required String label,
  required Color accent,
  required Color surface,
  required VoidCallback? onTap,
}) {
  final chip = DecoratedBox(
    key: key,
    decoration: BoxDecoration(
      color: surface.withValues(alpha: 0.92),
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      border: Border.all(color: accent, width: 1),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: accent, fontSize: 13)),
        ],
      ),
    ),
  );
  return onTap == null
      ? chip
      : GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: chip,
        );
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

/// SETLIO-UI: Pfeil-Schaltfläche für „Davor/Danach einfügen" — die
/// sichtbare Text-Beschriftung entfällt, der Pfeil steht zentriert
/// (oben = davor, unten = danach). VoiceOver liest weiterhin den
/// vollen Text, Tap-Ziel mindestens 44×44 pt. EIN gemeinsames Widget
/// für alle Inline-Menüs mit beidseitigem Einfügen — keine Kopien.
/// [onTap] null = ausgegraut (keine Bearbeitungsrechte).
class GrowInsertArrowButton extends StatelessWidget {
  const GrowInsertArrowButton.before({super.key, required this.onTap})
      : up = true;
  const GrowInsertArrowButton.after({super.key, required this.onTap})
      : up = false;

  final bool up;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = up ? 'Davor einfügen' : 'Danach einfügen';
    return Expanded(
      child: Tooltip(
        message: label,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(44, 44),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          child: Icon(
            up ? Icons.arrow_upward : Icons.arrow_downward,
            size: 18,
            semanticLabel: label,
          ),
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

  // Der Scroll wird NICHT als zweite Animation gefahren, sondern direkt an
  // die Auf-/Zu-Animation gekoppelt: bei jedem Tick wird der Offset auf
  // den passenden Zwischenwert gesetzt. Zwei parallele Animationen mit
  // gleicher Dauer starten sonst einen Frame versetzt — dann klappt das
  // Menü sichtbar auf und der Scroll zieht erst hinterher nach.
  //
  // SET-52: Der Ausgleich stützt sich auf die GEMESSENE Lage der
  // gehaltenen Zeile (jeden Tick neu), nicht auf vorausberechnete
  // absolute Offsets. Lazy-Listen mit dynamischen Zeilenhöhen
  // (aufgeklappte Medleys!) schätzen die Geometrie abseits des
  // Viewports nur — absolute Ziele gegen `maxScrollExtent` gerechnet
  // sprangen dann willkürlich, sobald der Sliver seine Schätzung
  // mitten in der Animation korrigierte.
  ScrollController? _syncedScroll;
  double _syncStartPixels = 0;
  bool _syncing = false;

  /// Gemessener Anker: Kontext der gehaltenen Zeile (ihr RenderObject
  /// umfasst auch die wachsenden Menü-Bereiche), Start-Lage im Viewport
  /// und gewünschte Verschiebung je Animationswert.
  BuildContext? _anchorContext;
  double _anchorStartY = 0;
  double _anchorShiftPerValue = 0;

  /// Aktuelle Viewport-Lage des Ankers — null, wenn nicht messbar
  /// (Zeile aus dem Baum gefallen o. ä.); dann greift der alte
  /// Interpolations-Fallback.
  double? _measuredAnchorY(ScrollPosition position) {
    final context = _anchorContext;
    if (context == null || !context.mounted) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached) return null;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return null;
    return viewport.getOffsetToReveal(box, 0).offset - position.pixels;
  }

  void _tickScroll() {
    final controller = _syncedScroll;
    if (!_syncing || controller == null || !controller.hasClients) return;
    final position = controller.position;

    final measured = _measuredAnchorY(position);
    if (measured != null) {
      final targetY = _anchorStartY + _anchorShiftPerValue * animation.value;
      final correction = measured - targetY;
      if (correction.abs() > 0.25) {
        controller.jumpTo(
          (position.pixels + correction).clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          ),
        );
      }
      return;
    }

    final target = _syncStartPixels + _scrollDelta * animation.value;
    controller.jumpTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
  }

  void _startScrollSync(
    ScrollController? controller,
    double delta, {
    BuildContext? anchorContext,
    double anchorShiftPerValue = 0,
  }) {
    _stopScrollSync();
    if (controller == null || !controller.hasClients) return;
    _syncedScroll = controller;
    _syncStartPixels = controller.position.pixels;
    _scrollDelta = delta;
    _anchorContext = anchorContext;
    _anchorShiftPerValue = anchorShiftPerValue;
    _anchorStartY = _measuredAnchorY(controller.position) ?? 0;
    _syncing = true;
    animation.addListener(_tickScroll);
  }

  void _stopScrollSync() {
    if (!_syncing) return;
    animation.removeListener(_tickScroll);
    _syncing = false;
    _syncedScroll = null;
    _anchorContext = null;
  }

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

    // SET-52: gewünschte End-Verschiebung der gehaltenen Zeile — rein
    // aus GEMESSENER Geometrie (Zeilenlage + Viewporthöhe), ohne die
    // unzuverlässigen Extent-Schätzungen der Lazy-Liste. 0 = Fixpunkt;
    // an den Rändern nur die minimale Sichtbarkeits-Korrektur.
    var rowShift = 0.0;
    if (position != null) {
      final box = itemContext.findRenderObject();
      if (box is RenderBox) {
        final viewport = RenderAbstractViewport.maybeOf(box);
        if (viewport != null) {
          final y0 =
              viewport.getOffsetToReveal(box, 0).offset - position.pixels;
          final rowH = box.size.height;
          final h = position.viewportDimension;
          if (y0 < sectionHeight) {
            rowShift = sectionHeight - y0; // Menü oben freischieben
          } else if (y0 + rowH + sectionHeight > h) {
            rowShift = (h - rowH - sectionHeight) - y0; // unten freischieben
          }
        }
      }
    }

    _openId = id;
    notifyListeners();
    // Der Anker (Zeile SAMT wachsender Bereiche) wandert je Wert um
    // (rowShift − sectionHeight): der obere Bereich wächst aus der
    // Zeilen-Oberkante, die Spaltenoberkante liegt also am Ende genau
    // eine Bereichshöhe über der Zeile.
    _startScrollSync(
      scrollController,
      delta,
      anchorContext: itemContext,
      anchorShiftPerValue: rowShift - sectionHeight,
    );
    _controller.forward(from: 0);
  }

  /// Schließt das offene Menü und fährt den Scroll-Ausgleich zurück.
  void close({ScrollController? scrollController}) {
    if (_openId == null) return;
    // Der Sync läuft rückwärts weiter: animation.value fällt auf 0, der
    // Offset landet damit wieder auf dem Ausgangswert. Basis neu setzen,
    // falls zwischendurch von Hand gescrollt wurde — sonst spränge es.
    final synced = _syncedScroll;
    if (_syncing && (synced?.hasClients ?? false)) {
      _syncStartPixels = synced!.position.pixels - _scrollDelta;
      // SET-52: auch den gemessenen Anker neu einhängen — die Zeile
      // bleibt beim Zufahren ab ihrer JETZIGEN Lage der Fixpunkt.
      final measured = _measuredAnchorY(synced.position);
      if (measured != null) {
        _anchorStartY = measured - _anchorShiftPerValue * animation.value;
      }
    }
    _controller.reverse().whenComplete(() {
      _stopScrollSync();
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
    _stopScrollSync();
    animation.dispose();
    _controller.dispose();
    super.dispose();
  }
}
