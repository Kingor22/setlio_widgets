import 'package:flutter/material.dart';
import 'package:setlio_shared/setlio_shared.dart';

/// Löschen per Wisch — aber NIE allein durch den Wisch.
///
/// Nach links wischen legt ein rotes Löschfeld frei, die Zeile bleibt
/// offen stehen. Gelöscht wird erst, wenn man das Feld antippt. Wisch
/// und Tipp zusammen SIND die Bestätigung; ein zusätzlicher Dialog
/// entfällt.
///
/// Ausdrücklich NICHT die zweite iOS-Variante, bei der ein voller Zug
/// bis zum Rand sofort löscht: genau so passieren die versehentlichen
/// Löschungen, die es hier zu verhindern gilt. Es gibt keinen Weg, über
/// diese Komponente ohne Tipp zu löschen.
///
/// Wegwischen, woanders hintippen oder eine andere Zeile öffnen
/// verwirft die Aktion.
class SwipeRevealDelete extends StatefulWidget {
  const SwipeRevealDelete({
    super.key,
    required this.itemKey,
    required this.enabled,
    required this.onDelete,
    required this.child,
    this.label = 'Löschen',
    this.icon = Icons.delete_outline,
    this.borderRadius = 11,
    this.leadingLabel,
    this.leadingIcon,
    this.onLeading,
    this.leadingColor = const Color(0xFF4EA8DE),
  });

  /// Identität der Zeile — daran erkennt die Komponente, ob eine ANDERE
  /// Zeile geöffnet wurde, und schliesst sich dann selbst.
  final Object itemKey;

  /// false: kein Wischen (Auswahlmodus, fehlendes Recht, offenes Menü).
  final bool enabled;

  final VoidCallback onDelete;
  final Widget child;
  final String label;
  final IconData icon;
  final double borderRadius;

  /// Zweite Aktion in der Gegenrichtung (nach rechts wischen), z. B.
  /// „In Ordner". Nicht destruktiv, deshalb im Akzent statt in Rot.
  /// Ohne [onLeading] lässt sich nur nach links wischen.
  final String? leadingLabel;
  final IconData? leadingIcon;
  final VoidCallback? onLeading;

  /// Himmelblau statt Rot: die Aktion ist nicht destruktiv, und sie darf
  /// auch nicht mit dem Türkis verwechselt werden — das steht in
  /// Setronome für „verweist auf Setlio".
  final Color leadingColor;

  @override
  State<SwipeRevealDelete> createState() => _SwipeRevealDeleteState();
}

/// Nur eine Zeile ist gleichzeitig offen — app-weit. Öffnet man eine
/// zweite, schliesst die erste; sonst stünden mehrere scharfe
/// Löschfelder gleichzeitig herum.
final ValueNotifier<Object?> _openItem = ValueNotifier<Object?>(null);

class _SwipeRevealDeleteState extends State<SwipeRevealDelete>
    with SingleTickerProviderStateMixin {
  static const _actionWidth = 92.0;

  /// Negativ = Aktion links freigelegt (nach rechts gewischt),
  /// positiv = Löschfeld rechts freigelegt.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    lowerBound: -1,
    upperBound: 1,
    value: 0,
    duration: const Duration(milliseconds: 180),
  );

  bool get _hasLeading => widget.onLeading != null;

  bool get _isOpen => _openItem.value == widget.itemKey;

  @override
  void initState() {
    super.initState();
    _openItem.addListener(_onOpenItemChanged);
  }

  void _onOpenItemChanged() {
    if (!mounted) return;
    if (_isOpen) return;
    if (_controller.value != 0) _controller.animateTo(0);
  }

  @override
  void didUpdateWidget(covariant SwipeRevealDelete oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Wird die Zeile stillgelegt (z. B. Auswahlmodus an), darf kein
    // offenes Löschfeld stehen bleiben.
    if (!widget.enabled && _isOpen) _close();
  }

  @override
  void dispose() {
    _openItem.removeListener(_onOpenItemChanged);
    if (_isOpen) _openItem.value = null;
    _controller.dispose();
    super.dispose();
  }

  void _open() => _openItem.value = widget.itemKey;

  void _close() {
    if (_isOpen) _openItem.value = null;
  }

  /// Zustand beim Beginn der Geste. Eine Geste darf immer nur EINEN
  /// Schritt weit gehen: aus dem offenen Löschfeld führt ein Wisch nach
  /// rechts zurück auf neutral — und nicht in einem Zug weiter zur
  /// Ordner-Aktion. Sonst kommt man aus der Ansicht nicht mehr heraus.
  double _dragStart = 0;

  void _onDragStart(DragStartDetails details) {
    _dragStart = _controller.value;
  }

  /// Erlaubter Bereich dieser Geste — abhängig davon, wo sie begann.
  (double, double) get _dragBounds {
    if (_dragStart > 0.5) return (0, 1); // offen: nur zumachen
    if (_dragStart < -0.5) return (-1, 0); // Ordner offen: nur zumachen
    return (_hasLeading ? -1.0 : 0.0, 1.0); // neutral: beide Richtungen
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;
    // Nach links zieht auf, nach rechts wieder zu.
    final next = _controller.value - details.primaryDelta! / _actionWidth;
    final (lower, upper) = _dragBounds;
    _controller.value = next.clamp(lower, upper);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.enabled) return;
    final velocity = details.primaryVelocity ?? 0;
    final value = _controller.value;
    final (lower, upper) = _dragBounds;

    // Schwung entscheidet, sonst die halbe Strecke. Ein voller Zug löst
    // NICHTS aus — er öffnet nur.
    final double target;
    if (velocity < -300) {
      target = upper;
    } else if (velocity > 300) {
      target = lower;
    } else if (value > 0.5) {
      target = 1;
    } else if (value < -0.5) {
      target = -1;
    } else {
      target = 0;
    }

    // NICHT forward()/reverse(): die laufen auf die Grenzen des
    // Controllers (-1 bzw. 1) und träfen die Mitte nie.
    if (target == 0) {
      _close();
    } else {
      _open();
    }
    _controller.animateTo(target);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final value = _controller.value;
          final offset = -_actionWidth * value;
          return Stack(
            children: [
              // Die Aktionsfelder liegen hinter der Zeile und werden
              // durch das Verschieben freigelegt.
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _SwipeAction(
                    width: _actionWidth,
                    visible: value > 0,
                    label: widget.label,
                    icon: widget.icon,
                    borderRadius: widget.borderRadius,
                    color: const Color(DesignTokens.red),
                    onTap: () {
                      _close();
                      widget.onDelete();
                    },
                  ),
                ),
              ),
              if (_hasLeading)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _SwipeAction(
                      width: _actionWidth,
                      visible: value < 0,
                      label: widget.leadingLabel ?? '',
                      icon: widget.leadingIcon ?? Icons.folder_outlined,
                      borderRadius: widget.borderRadius,
                      color: widget.leadingColor,
                      onTap: () {
                        _close();
                        widget.onLeading!();
                      },
                    ),
                  ),
                ),
              Transform.translate(
                offset: Offset(offset, 0),
                child: value == 0
                    ? widget.child
                    // Offen: ein Tipp auf die Zeile schliesst nur, statt
                    // sie zu öffnen — wie auf iOS.
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _close,
                        child: IgnorePointer(child: widget.child),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SwipeAction extends StatelessWidget {
  const _SwipeAction({
    required this.width,
    required this.visible,
    required this.label,
    required this.icon,
    required this.borderRadius,
    required this.color,
    required this.onTap,
  });

  final double width;
  final bool visible;
  final String label;
  final IconData icon;
  final double borderRadius;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: const Color(DesignTokens.red),
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: width - 16,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
