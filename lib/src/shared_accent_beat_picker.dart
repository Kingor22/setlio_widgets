import 'package:flutter/material.dart';

/// One LED per beat in the bar; tapping a beat toggles whether it's
/// accented — any number of beats can be selected at once.
class SharedAccentBeatPicker extends StatelessWidget {
  const SharedAccentBeatPicker({
    super.key,
    required this.beatsPerBar,
    required this.selectedBeats,
    required this.onToggle,
  });

  final int beatsPerBar;
  final Set<int> selectedBeats;
  final void Function(int) onToggle;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    final background = Theme.of(context).colorScheme.surface;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var beat = 1; beat <= beatsPerBar; beat++)
          GestureDetector(
            onTap: () => onToggle(beat),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selectedBeats.contains(beat) ? foreground : background,
                border: Border.all(color: foreground, width: 2),
              ),
              child: Text(
                '$beat',
                style: TextStyle(
                  color: selectedBeats.contains(beat) ? background : foreground,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
