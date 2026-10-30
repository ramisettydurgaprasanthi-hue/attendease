import 'package:flutter/material.dart';

/// All colors used by the UI. Change them here to restyle the whole app.
class UiColors {
  static const primary = Color(0xFF5B5BD6);
  static const success = Color(0xFF2E9E6B); // on track / present
  static const warning = Color(0xFFF59E0B); // close to the limit
  static const danger = Color(0xFFE5484D); // below target / absent

  static const gradientOnTrack = [Color(0xFF4F46E5), Color(0xFF7C3AED)];
  static const gradientBelow = [Color(0xFFEA580C), Color(0xFFF59E0B)];

  static bool isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  /// Background of cards and inputs.
  static Color surface(BuildContext c) =>
      isDark(c) ? const Color(0xFF1B1D27) : Colors.white;

  /// Secondary (grey) text.
  static Color mutedText(BuildContext c) =>
      isDark(c) ? Colors.white60 : Colors.black54;

  static List<BoxShadow> softShadow(BuildContext c) => isDark(c)
      ? []
      : [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];
}