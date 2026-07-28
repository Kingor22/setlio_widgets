/// Geteilte Flutter-Widgets für Setlios und Setronomes Song-Editor.
///
/// Bewusst kein Riverpod/Supabase (Versionsfalle zwischen Setronomes
/// Riverpod 2 und Setlios Riverpod 3) – nur plain, theme-getriebene
/// Widgets. Styling über `Theme.of(context).colorScheme` + Radien aus
/// `setlio_shared`s `DesignTokens`.
library;

export 'src/shared_accent_beat_picker.dart';
export 'src/shared_bar_overrides_editor.dart';
export 'src/shared_card_chrome.dart';
export 'src/shared_inline_grow_menu.dart';
export 'src/shared_removable_tag_chip.dart';
export 'src/shared_step_button.dart';
export 'src/shared_subdivision_picker.dart';
export 'src/shared_tap_tempo_button.dart';
export 'src/shared_wheel_picker.dart';
export 'src/swipe_reveal_delete.dart';
