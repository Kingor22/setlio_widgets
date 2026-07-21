import 'package:flutter/material.dart';

/// Horizontal row of four note-symbol buttons — quarter (1), eighth (2),
/// sixteenth (4), triplet (3). The active option glows in [activeColor];
/// inactive ones are shown at 35% opacity.
class SharedSubdivisionPicker extends StatelessWidget {
  const SharedSubdivisionPicker({
    super.key,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  final int value;
  final Color activeColor;
  final void Function(int) onChanged;

  static const _options = [1, 2, 4, 3]; // quarter, eighth, sixteenth, triplet

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in _options) ...[
          if (option != _options.first) const SizedBox(width: 10),
          GestureDetector(
            onTap: () => onChanged(option),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 34,
              decoration: option == value
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: activeColor.withValues(alpha: 0.12),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                        ),
                      ],
                    )
                  : null,
              child: Opacity(
                opacity: option == value ? 1.0 : 0.35,
                child: CustomPaint(
                  size: const Size(44, 34),
                  painter: NoteSymbolPainter(
                    type: option,
                    color: option == value
                        ? activeColor
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Draws a musical note symbol for the given [type]:
/// 1 = quarter note (♩), 2 = eighth (♪), 4 = sixteenth (♬-like), 3 = triplet.
class NoteSymbolPainter extends CustomPainter {
  const NoteSymbolPainter({required this.type, required this.color});

  final int type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (type == 3) {
      _paintTriplet(canvas, size);
    } else {
      _paintNote(canvas, size);
    }
  }

  void _paintNote(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final nhCx = w * 0.50;
    final nhCy = h * 0.80;
    canvas.save();
    canvas.translate(nhCx, nhCy);
    canvas.rotate(-0.38);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.30, height: h * 0.23),
      fill,
    );
    canvas.restore();

    final stemX = nhCx + w * 0.12;
    final stemBottom = nhCy - h * 0.06;
    final stemTop = h * 0.10;
    stroke.strokeWidth = w * 0.055;
    canvas.drawLine(Offset(stemX, stemBottom), Offset(stemX, stemTop), stroke);

    if (type == 2 || type == 4) {
      stroke.strokeWidth = w * 0.05;
      final flag1 = Path()
        ..moveTo(stemX, stemTop)
        ..cubicTo(
          stemX + w * 0.30,
          stemTop + h * 0.08,
          stemX + w * 0.28,
          stemTop + h * 0.24,
          stemX + w * 0.04,
          stemTop + h * 0.30,
        );
      canvas.drawPath(flag1, stroke);
    }
    if (type == 4) {
      final f2y = stemTop + h * 0.16;
      stroke.strokeWidth = w * 0.05;
      final flag2 = Path()
        ..moveTo(stemX, f2y)
        ..cubicTo(
          stemX + w * 0.30,
          f2y + h * 0.08,
          stemX + w * 0.28,
          f2y + h * 0.24,
          stemX + w * 0.04,
          f2y + h * 0.30,
        );
      canvas.drawPath(flag2, stroke);
    }
  }

  void _paintTriplet(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final nhCxs = [w * 0.12, w * 0.43, w * 0.74];
    final nhCy = h * 0.82;
    final stemTopY = h * 0.35;

    for (final cx in nhCxs) {
      canvas.save();
      canvas.translate(cx, nhCy);
      canvas.rotate(-0.30);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: w * 0.18,
          height: h * 0.17,
        ),
        fill,
      );
      canvas.restore();
    }

    stroke.strokeWidth = w * 0.045;
    stroke.strokeCap = StrokeCap.butt;
    for (final cx in nhCxs) {
      final stemX = cx + w * 0.065;
      canvas.drawLine(
        Offset(stemX, nhCy - h * 0.09),
        Offset(stemX, stemTopY),
        stroke,
      );
    }

    stroke.strokeWidth = h * 0.085;
    stroke.strokeCap = StrokeCap.butt;
    canvas.drawLine(
      Offset(nhCxs[0] + w * 0.065, stemTopY),
      Offset(nhCxs[2] + w * 0.065, stemTopY),
      stroke,
    );

    final textSpan = TextSpan(
      text: '3',
      style: TextStyle(
        color: color,
        fontSize: h * 0.28,
        fontWeight: FontWeight.bold,
        height: 1,
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, Offset(w * 0.5 - tp.width / 2, h * 0.02));
  }

  @override
  bool shouldRepaint(NoteSymbolPainter old) =>
      old.type != type || old.color != color;
}
