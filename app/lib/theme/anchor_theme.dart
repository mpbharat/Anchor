import 'package:flutter/material.dart';

/// Anchor — V2 "Duo" design tokens (neobrutalist).
/// Paper ground, cobalt accent, yellow on the load, coral for refusal only.
class AnchorColors {
  static const scr = Color(0xFFF4ECD8); // screen background (paper)
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF16203A); // borders + text
  static const dim = Color(0xFF8C8770);
  static const accent = Color(0xFF2B4FF0); // cobalt
  static const energy = Color(0xFFFFD21E); // yellow — load gauge, week badge
  static const alert = Color(0xFFFF5236); // coral — refusal ONLY
  static const ok = Color(0xFF2FA862);
}

/// Neobrutalist surface: thick dark border + hard offset shadow (no blur).
class AnchorBox {
  static BoxDecoration surface({Color? bg, double radius = 9, double shadow = 5}) {
    return BoxDecoration(
      color: bg ?? AnchorColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AnchorColors.ink, width: 2.5),
      boxShadow: [
        BoxShadow(color: AnchorColors.ink, offset: Offset(shadow, shadow), blurRadius: 0),
      ],
    );
  }
}

ThemeData anchorTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AnchorColors.scr,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AnchorColors.accent,
      primary: AnchorColors.accent,
      background: AnchorColors.scr,
    ),
    textTheme: const TextTheme(
      // Heavy display for wordmarks/headlines; monospace is used inline for data/labels.
      displaySmall: TextStyle(fontWeight: FontWeight.w900, color: AnchorColors.ink, letterSpacing: 0.5),
      titleLarge: TextStyle(fontWeight: FontWeight.w900, color: AnchorColors.ink),
      bodyMedium: TextStyle(color: AnchorColors.ink),
    ),
  );
}
