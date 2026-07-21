import 'package:flutter/material.dart';

/// Löschbarer Tag/Part-Chip (Tags, Parts, ...) – Rand-Pill mit Kreuz-Icon.
class SharedRemovableTagChip extends StatelessWidget {
  const SharedRemovableTagChip({
    super.key,
    required this.label,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: foreground),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: foreground)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: foreground),
          ),
        ],
      ),
    );
  }
}
