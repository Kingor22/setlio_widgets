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

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  bool get _isOpen => _openItem.value == widget.itemKey;

  @override
  void initState() {
    super.initState();
    _openItem.addListener(_onOpenItemChanged);
  }

  void _onOpenItemChanged() {
    if (!mounted) return;
    if (_isOpen) {
      _controller.forward();
    } else if (_controller.value != 0) {
      _controller.reverse();
    }
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

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;
    // Nach links zieht auf, nach rechts wieder zu.
    final next = _controller.value - details.primaryDelta! / _actionWidth;
    _controller.value = next.clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.enabled) return;
    final velocity = details.primaryVelocity ?? 0;
    // Schneller Zug entscheidet, sonst die halbe Strecke. Ein voller Zug
    // löst NICHTS aus — er öffnet nur.
    final shouldOpen = velocity < -300
        ? true
        : velocity > 300
            ? false
            : _controller.value > 0.5;
    if (shouldOpen) {
      _open();
      _controller.forward();
    } else {
      _close();
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final offset = -_actionWidth * _controller.value;
          return Stack(
            children: [
              // Löschfeld liegt hinter der Zeile und wird freigelegt.
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _DeleteAction(
                    width: _actionWidth,
                    visible: _controller.value > 0,
                    label: widget.label,
                    icon: widget.icon,
                    borderRadius: widget.borderRadius,
                    onTap: () {
                      _close();
                      widget.onDelete();
                    },
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(offset, 0),
                child: _controller.value == 0
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

class _DeleteAction extends StatelessWidget {
  const _DeleteAction({
    required this.width,
    required this.visible,
    required this.label,
    required this.icon,
    required this.borderRadius,
    required this.onTap,
  });

  final double width;
  final bool visible;
  final String label;
  final IconData icon;
  final double borderRadius;
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
