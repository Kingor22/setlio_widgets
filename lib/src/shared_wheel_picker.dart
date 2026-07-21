import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:setlio_shared/setlio_shared.dart';

import 'shared_card_chrome.dart';

/// Vertical wheel picker (Takt, Notenwert, Count-In, BPM, ...).
/// Shows [visibleItems] rows at once; the centre row is the selected value.
/// Fires [onChanged] with haptic feedback on each snap to centre.
class SharedWheelPicker<T> extends StatefulWidget {
  const SharedWheelPicker({
    super.key,
    required this.items,
    required this.labels,
    required this.value,
    required this.onChanged,
    this.itemExtent = 44.0,
    this.visibleItems = 3,
    this.width,
    this.fontSize = 20.0,
  }) : assert(items.length == labels.length);

  final List<T> items;
  final List<String> labels;
  final T value;
  final void Function(T) onChanged;
  final double itemExtent;
  final int visibleItems;
  final double? width;
  final double fontSize;

  @override
  State<SharedWheelPicker<T>> createState() => _SharedWheelPickerState<T>();
}

class _SharedWheelPickerState<T> extends State<SharedWheelPicker<T>> {
  late FixedExtentScrollController _ctrl;

  int _indexOf(T value) {
    final i = widget.items.indexOf(value);
    return i >= 0 ? i : 0;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = FixedExtentScrollController(initialItem: _indexOf(widget.value));
  }

  @override
  void didUpdateWidget(covariant SharedWheelPicker<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _ctrl.hasClients) {
      final next = _indexOf(widget.value);
      if (_ctrl.selectedItem != next) {
        _ctrl.animateToItem(
          next,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    final lineColor = fg.withValues(alpha: 0.12);
    final totalH = widget.itemExtent * widget.visibleItems;

    return Container(
      decoration:
          sharedCardDecoration(context, radius: DesignTokens.radiusCard),
      child: SizedBox(
        width: widget.width,
        height: totalH,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle selection indicator — two thin rules bounding the centre slot.
            Positioned(
              top: (totalH - widget.itemExtent) / 2,
              left: 12,
              right: 12,
              child: IgnorePointer(
                child: Column(
                  children: [
                    Container(height: 0.5, color: lineColor),
                    SizedBox(height: widget.itemExtent - 1),
                    Container(height: 0.5, color: lineColor),
                  ],
                ),
              ),
            ),
            ListWheelScrollView.useDelegate(
              controller: _ctrl,
              itemExtent: widget.itemExtent,
              perspective: 0.003,
              diameterRatio: 4.5,
              overAndUnderCenterOpacity: 0.35,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (i) {
                HapticFeedback.selectionClick();
                widget.onChanged(widget.items[i]);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: widget.items.length,
                builder: (context, index) => Center(
                  child: Text(
                    widget.labels[index],
                    style: GoogleFonts.getFont(
                      DesignTokens.bodyFont,
                      color: fg,
                      fontSize: widget.fontSize,
                    ).copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens a bottom sheet containing a [SharedWheelPicker].
/// [onChanged] fires in real-time as the wheel scrolls — no confirm button.
/// The sheet is dismissed by swiping down or tapping outside.
Future<void> showSharedWheelPickerSheet<T>({
  required BuildContext context,
  required List<T> items,
  required List<String> labels,
  required T value,
  required void Function(T) onChanged,
  String title = '',
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(
                  ctx,
                ).colorScheme.onSurface.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (title.isNotEmpty) ...[
              Text(
                title,
                style: GoogleFonts.getFont(
                  DesignTokens.monoFont,
                  color: Theme.of(ctx)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 14),
            ],
            SharedWheelPicker<T>(
              items: items,
              labels: labels,
              value: value,
              onChanged: onChanged,
              visibleItems: 5,
              fontSize: 26,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
