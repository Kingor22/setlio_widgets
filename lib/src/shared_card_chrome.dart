import 'package:flutter/material.dart';
import 'package:setlio_shared/setlio_shared.dart';

/// Gemeinsame Karten-Optik für dieses Paket (Setlios DESIGN.md-Rezept:
/// Fläche, Rahmen, zweilagiger weicher Schatten) – bewusst nur über
/// `Theme.of(context).colorScheme` + [DesignTokens], ohne Abhängigkeit
/// von app-eigenen Theme-Extensions (Setronomes `AppPalette`, Setlios
/// Card-Widgets), damit dieses Paket in beiden Apps ohne Anpassung
/// funktioniert – beide Themes sind ohnehin auf dieselben Tokens gemappt.
BoxDecoration sharedCardDecoration(
  BuildContext context, {
  double radius = DesignTokens.radiusCard,
}) {
  final scheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: scheme.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: scheme.onSurface.withValues(alpha: 0.14),
      width: 0.5,
    ),
    boxShadow: const [
      BoxShadow(color: Color(0x47000000), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(
        color: Color(0x47000000),
        blurRadius: 30,
        offset: Offset(0, 10),
      ),
    ],
  );
}
