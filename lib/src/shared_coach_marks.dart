import 'package:flutter/material.dart';

/// Aufgabe 43: Coach-Marks — die EINE Tutorial-Komponente der
/// Setlio-Familie. Kleine Hinweis-Sprechblasen auf den ECHTEN
/// Elementen: der Hintergrund dunkelt ab, das erklärte Element bleibt
/// als „Spotlight" ausgespart. Kontextuell pro Bereich (der Aufrufer
/// entscheidet, wann eine Tour startet und merkt sich den
/// Gesehen-Status); jederzeit überspringbar. Texte kommen als fertige
/// Strings aus dem i18n-System des Aufrufers.
class CoachStep {
  const CoachStep({required this.title, required this.text, this.targetKey});

  final String title;
  final String text;

  /// Element, das hervorgehoben wird. null (oder aktuell nicht gebaut)
  /// → die Sprechblase steht mittig, ohne Spotlight.
  final GlobalKey? targetKey;
}

/// Zeigt eine Bereichs-Tour. Liefert true, wenn sie bis zum Ende
/// durchlaufen wurde, false bei „Überspringen" — der Aufrufer merkt
/// sich in BEIDEN Fällen „gesehen" (nie wieder automatisch).
Future<bool> showCoachMarks(
  BuildContext context, {
  required List<CoachStep> steps,
  required Color accentColor,
  String skipLabel = 'Überspringen',
  String nextLabel = 'Weiter',
  String doneLabel = 'Fertig',
}) async {
  if (steps.isEmpty) return true;
  final finished = await Navigator.of(context).push<bool>(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, _) => FadeTransition(
        opacity: animation,
        child: _CoachMarksOverlay(
          steps: steps,
          accentColor: accentColor,
          skipLabel: skipLabel,
          nextLabel: nextLabel,
          doneLabel: doneLabel,
        ),
      ),
    ),
  );
  return finished ?? false;
}

class _CoachMarksOverlay extends StatefulWidget {
  const _CoachMarksOverlay({
    required this.steps,
    required this.accentColor,
    required this.skipLabel,
    required this.nextLabel,
    required this.doneLabel,
  });

  final List<CoachStep> steps;
  final Color accentColor;
  final String skipLabel;
  final String nextLabel;
  final String doneLabel;

  @override
  State<_CoachMarksOverlay> createState() => _CoachMarksOverlayState();
}

class _CoachMarksOverlayState extends State<_CoachMarksOverlay> {
  int _index = 0;

  CoachStep get _step => widget.steps[_index];

  /// Ziel-Rechteck des aktuellen Schritts in globalen Koordinaten —
  /// null, wenn kein (gebautes) Ziel existiert.
  Rect? get _targetRect {
    final key = _step.targetKey;
    final targetContext = key?.currentContext;
    if (targetContext == null) return null;
    final box = targetContext.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final origin = box.localToGlobal(Offset.zero);
    return (origin & box.size).inflate(6);
  }

  void _next() {
    if (_index + 1 >= widget.steps.length) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rect = _targetRect;
    final screen = MediaQuery.sizeOf(context);
    final last = _index == widget.steps.length - 1;

    // Sprechblase über oder unter dem Ziel — wo mehr Platz ist.
    final below = rect == null || rect.center.dy < screen.height / 2;

    return Stack(
      children: [
        // Abdunkeln mit Spotlight-Aussparung; Tap überall = Weiter.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _next,
            child: TweenAnimationBuilder<Rect?>(
              tween: RectTween(
                end: rect ??
                    Rect.fromCenter(
                      center: Offset(screen.width / 2, screen.height / 2),
                      width: 0,
                      height: 0,
                    ),
              ),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (context, animatedRect, _) => CustomPaint(
                painter: _SpotlightPainter(
                  hole: rect == null ? null : animatedRect,
                  accent: widget.accentColor,
                ),
              ),
            ),
          ),
        ),
        // Sprechblase.
        AnimatedPositioned(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          left: 20,
          right: 20,
          top: rect == null
              ? screen.height * 0.4
              : below
                  ? rect.bottom + 14
                  : null,
          bottom: rect != null && !below ? screen.height - rect.top + 14 : null,
          child: _Bubble(
            step: _step,
            index: _index,
            count: widget.steps.length,
            accent: widget.accentColor,
            skipLabel: widget.skipLabel,
            nextLabel: last ? widget.doneLabel : widget.nextLabel,
            onSkip: () => Navigator.of(context).pop(false),
            onNext: _next,
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.step,
    required this.index,
    required this.count,
    required this.accent,
    required this.skipLabel,
    required this.nextLabel,
    required this.onSkip,
    required this.onNext,
  });

  final CoachStep step;
  final int index;
  final int count;
  final Color accent;
  final String skipLabel;
  final String nextLabel;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(step.text, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Schritt-Punkte.
                    for (var i = 0; i < count; i++)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == index
                              ? accent
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: .25,
                                ),
                        ),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: onSkip,
                      child: Text(skipLabel),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: accent),
                      onPressed: onNext,
                      child: Text(nextLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({required this.hole, required this.accent});

  final Rect? hole;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = Colors.black.withValues(alpha: .62);
    final full = Path()..addRect(Offset.zero & size);
    if (hole == null || hole!.isEmpty) {
      canvas.drawPath(full, dim);
      return;
    }
    final spot = Path()
      ..addRRect(RRect.fromRectAndRadius(hole!, const Radius.circular(12)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, spot),
      dim,
    );
    // Feiner Akzentrahmen um das Spotlight.
    canvas.drawRRect(
      RRect.fromRectAndRadius(hole!, const Radius.circular(12)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = accent.withValues(alpha: .9),
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole || oldDelegate.accent != accent;
}
