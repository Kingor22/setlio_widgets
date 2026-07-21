import 'package:flutter/material.dart';

/// Kleiner +/- Icon-Button für Stepper-Reihen (BPM, Capo, ...).
class SharedStepButton extends StatelessWidget {
  const SharedStepButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return IconButton(onPressed: onTap, icon: Icon(icon, color: foreground));
  }
}
