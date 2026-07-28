import 'package:flutter/material.dart';
import 'package:setlio_shared/setlio_shared.dart';

import 'shared_wheel_picker.dart';

/// SET-46: Takt-Editor für Medley-Teile mit fester Taktzahl — einzelne
/// Takte bekommen eine abweichende Taktart (z. B. Takt 12 als 6/4 in
/// einem 4/4-Teil). Gemeinsame Fassung für Setlio (iPad + Web) und
/// Setronome (iPad); die Apps entscheiden selbst, WO sie ihn anbieten.
///
/// Bedienung: Raster aller Takte, Sondertakte im Akzent. Tippen öffnet
/// die Taktart-Wahl; „Standard" setzt den Takt zurück.
Future<Map<int, List<int>>?> showBarOverridesEditor(
  BuildContext context, {
  required int barCount,
  required int defaultBeats,
  required int defaultNote,
  required Map<int, List<int>> initial,
}) {
  return showDialog<Map<int, List<int>>>(
    context: context,
    builder: (context) => _BarOverridesDialog(
      barCount: barCount,
      defaultBeats: defaultBeats,
      defaultNote: defaultNote,
      initial: initial,
    ),
  );
}

class _BarOverridesDialog extends StatefulWidget {
  const _BarOverridesDialog({
    required this.barCount,
    required this.defaultBeats,
    required this.defaultNote,
    required this.initial,
  });

  final int barCount;
  final int defaultBeats;
  final int defaultNote;
  final Map<int, List<int>> initial;

  @override
  State<_BarOverridesDialog> createState() => _BarOverridesDialogState();
}

class _BarOverridesDialogState extends State<_BarOverridesDialog> {
  late final Map<int, List<int>> _overrides = {
    // Takte jenseits der festen Taktzahl still verwerfen — die kann es
    // nach dem Kürzen eines Teils geben.
    for (final e in widget.initial.entries)
      if (e.key >= 1 && e.key <= widget.barCount) e.key: List.of(e.value),
  };

  Future<void> _editBar(int bar) async {
    final current = _overrides[bar];
    var beats = current?[0] ?? widget.defaultBeats;
    var note = (current?.length ?? 0) > 1 ? current![1] : widget.defaultNote;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text('Takt $bar'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SharedWheelPicker<int>(
                items: [for (var i = 1; i <= 12; i++) i],
                labels: [for (var i = 1; i <= 12; i++) '$i'],
                value: beats.clamp(1, 12),
                onChanged: (v) => setLocal(() => beats = v),
                width: 64,
                visibleItems: 3,
                fontSize: 20,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('/', style: TextStyle(fontSize: 22)),
              ),
              SharedWheelPicker<int>(
                items: const [2, 4, 8, 16],
                labels: const ['2', '4', '8', '16'],
                value: const [2, 4, 8, 16].contains(note) ? note : 4,
                onChanged: (v) => setLocal(() => note = v),
                width: 64,
                visibleItems: 3,
                fontSize: 20,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('reset'),
              child: const Text('Standard'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('set'),
              child: const Text('Übernehmen'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      if (result == 'reset') {
        _overrides.remove(bar);
      } else if (result == 'set') {
        if (beats == widget.defaultBeats && note == widget.defaultNote) {
          // Explizit auf den Standard gestellt = kein Sondertakt.
          _overrides.remove(bar);
        } else {
          _overrides[bar] = [beats, note];
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(
        'Takte bearbeiten '
        '(Standard ${widget.defaultBeats}/${widget.defaultNote})',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var bar = 1; bar <= widget.barCount; bar++)
                _barChip(bar, scheme),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_overrides),
          child: const Text('Speichern'),
        ),
      ],
    );
  }

  Widget _barChip(int bar, ColorScheme scheme) {
    final override = _overrides[bar];
    final isSpecial = override != null;
    final label = isSpecial
        ? '${override[0]}/${override.length > 1 ? override[1] : widget.defaultNote}'
        : '${widget.defaultBeats}/${widget.defaultNote}';
    return InkWell(
      key: Key('bar-$bar'),
      onTap: () => _editBar(bar),
      borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSpecial
              ? scheme.primary.withValues(alpha: 0.16)
              : scheme.surface,
          border: Border.all(
            color: isSpecial ? scheme.primary : scheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
        ),
        child: Column(
          children: [
            Text(
              '$bar',
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSpecial ? FontWeight.w600 : FontWeight.w400,
                color: isSpecial ? scheme.primary : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
