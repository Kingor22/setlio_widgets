import 'dart:async';

import 'package:flutter/material.dart';
import 'package:setlio_shared/setlio_shared.dart';

import 'shared_card_chrome.dart';

/// Number of taps that make up one tap-tempo measurement.
const int kTapTempoReferenceTaps = 12;

/// How long to wait after the last tap before treating the sequence as
/// abandoned — without some timeout the field would stay stuck on
/// "Tap weiter…" forever if the user stops mid-sequence.
const Duration kTapTempoTimeout = Duration(seconds: 3);

/// Tap-Tempo-Geste für BPM-Felder (Metronom-Home, Song-Editor). Dieses
/// Widget übernimmt nur Tap-Erfassung/Timing – der Aufrufer entscheidet,
/// wie "Tap weiter…" angezeigt wird und wo die berechnete BPM landet.
///
/// [onBpmCalculated] fires on every tap from the 2nd one onward in a
/// sequence (not just once at the end). 12 taps cap one measurement cycle.
class SharedTapTempoButton extends StatefulWidget {
  const SharedTapTempoButton({
    super.key,
    required this.onBpmCalculated,
    required this.onTappingChanged,
    this.enabled = true,
    this.large = false,
    this.bare = false,
  });

  final void Function(double bpm) onBpmCalculated;
  final void Function(bool isTapping) onTappingChanged;
  final bool enabled;

  /// Größerer Footprint, wenn der Button die Haupt-Tempo-Eingabe ist
  /// (Metronom-Home); kompakt neben BPM-Feld + Steppern (Song-Editor).
  final bool large;

  /// SET-62: NUR das Wort „Tap" — ohne Button-Chrome (Karte/Rand/
  /// Padding). Für das Drehrad-Zentrum, wo das Rad selbst der sichtbare
  /// Rahmen ist; Tap-Verhalten unverändert.
  final bool bare;

  @override
  State<SharedTapTempoButton> createState() => _SharedTapTempoButtonState();
}

class _SharedTapTempoButtonState extends State<SharedTapTempoButton> {
  final List<DateTime> _taps = [];
  Timer? _abandonTimer;

  void _onTap() {
    final now = DateTime.now();
    _abandonTimer?.cancel();

    if (_taps.isNotEmpty && now.difference(_taps.last) > kTapTempoTimeout) {
      _taps.clear();
    }

    final isFirstTapOfSequence = _taps.isEmpty;
    _taps.add(now);
    if (isFirstTapOfSequence) {
      widget.onTappingChanged(true);
    }

    // From the 2nd tap on there's at least one interval to average over —
    // report it immediately instead of waiting for the full cycle.
    if (_taps.length >= 2) {
      widget.onBpmCalculated(_averageBpm());
    }

    if (_taps.length >= kTapTempoReferenceTaps) {
      widget.onTappingChanged(false);
      _taps.clear();
      return;
    }

    _abandonTimer = Timer(kTapTempoTimeout, () {
      _taps.clear();
      widget.onTappingChanged(false);
    });
  }

  double _averageBpm() {
    var totalMs = 0;
    for (var i = 1; i < _taps.length; i++) {
      totalMs += _taps[i].difference(_taps[i - 1]).inMilliseconds;
    }
    final averageIntervalMs = totalMs / (_taps.length - 1);
    return 60000 / averageIntervalMs;
  }

  @override
  void dispose() {
    _abandonTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    final padding = widget.large
        ? const EdgeInsets.symmetric(horizontal: 40, vertical: 28)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 16);

    final label = Text(
      'Tap',
      style: TextStyle(
        color: foreground,
        fontSize: widget.large ? 22 : 16,
        fontWeight: FontWeight.w300,
      ),
    );

    return GestureDetector(
      onTap: widget.enabled ? _onTap : null,
      // bare: großzügige unsichtbare Tap-Fläche statt Button-Karte.
      behavior: widget.bare ? HitTestBehavior.opaque : null,
      child: Opacity(
        opacity: widget.enabled ? 1.0 : 0.4,
        child: widget.bare
            // Füllt die vom Aufrufer gegebene Box vollständig als
            // Tap-Fläche; die Schrift bleibt mittig und unverändert.
            ? Container(alignment: Alignment.center, child: label)
            : Container(
                padding: padding,
                decoration: sharedCardDecoration(
                  context,
                  radius: DesignTokens.radiusButton,
                ),
                child: label,
              ),
      ),
    );
  }
}
