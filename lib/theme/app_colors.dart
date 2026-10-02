import 'package:flutter/material.dart';

/// Single source of truth for ClearedToGo's palette.
///
/// Standing rule: no black or grey box/container fills anywhere in the app.
/// Card and container backgrounds are [cardBackground] (white), text is
/// [bodyText] (near-black) or [navy], and the navy / sky-blue / orange trio
/// is reserved for buttons, headers, and accents — not fills.
class AppColors {
  AppColors._();

  static const Color navy = Color(0xFF12395F);
  static const Color darkNavy = Color(0xFF0C2942);
  static const Color skyBlue = Color(0xFF8ECDE6);
  static const Color orange = Color(0xFFF5A623);

  static const Color cardBackground = Colors.white;
  static const Color pageBackground = Colors.white;
  static const Color bodyText = darkNavy;
  static const Color subtleText = Color(0xFF4A5C6B);
  static const Color border = Color(0xFFD7E1E8);

  static const LinearGradient headerGradient = LinearGradient(
    colors: [skyBlue, navy],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
