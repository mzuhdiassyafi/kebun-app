import 'package:flutter/material.dart';

/// Design tokens from the "Kebun Tokens" collection in Figma.
class KColors {
  static const canvas = Color(0xFFF6F3EC);
  static const surface = Color(0xFFFFFFFF);
  static const subtle = Color(0xFFEFEBE1);
  static const primary = Color(0xFF2F7D4F);
  static const primaryDark = Color(0xFF1F5A37);
  static const primarySoft = Color(0xFFE3F1E6);
  static const text = Color(0xFF1E2A22);
  static const textSecondary = Color(0xFF6B746C);
  static const inverse = Color(0xFFFFFFFF);
  static const border = Color(0xFFE8E3D8);
  static const success = Color(0xFF2F9E5B);
  static const successSoft = Color(0xFFE2F4E8);
  static const warning = Color(0xFFD98E04);
  static const warningSoft = Color(0xFFFDF1D8);
  static const danger = Color(0xFFD64545);
  static const dangerSoft = Color(0xFFFBE4E4);
  static const water = Color(0xFF3A8FD6);
  static const waterSoft = Color(0xFFE3F0FB);
  static const soil = Color(0xFF9C6B45);
  static const soilSoft = Color(0xFFF3E8DD);
  static const sun = Color(0xFFE9A23B);
  static const sunSoft = Color(0xFFFCEFD9);
}

class KSpace {
  static const s4 = 4.0, s8 = 8.0, s12 = 12.0, s16 = 16.0, s20 = 20.0, s24 = 24.0;
}

class KRadius {
  static const sm = 12.0, md = 16.0, lg = 24.0, full = 999.0;
}

/// Plus Jakarta Sans text styles (size / weight / line height).
class KText {
  static const _f = 'PlusJakartaSans';
  static TextStyle _s(double size, FontWeight w, double lh, [Color c = KColors.text]) =>
      TextStyle(fontFamily: _f, fontSize: size, fontWeight: w, height: lh / size, color: c, letterSpacing: 0);

  static final display = _s(28, FontWeight.w700, 34);
  static final h22 = _s(22, FontWeight.w700, 28);
  static final h18 = _s(18, FontWeight.w700, 24);
  static final title = _s(16, FontWeight.w600, 22);
  static final bodyMedium = _s(14, FontWeight.w500, 20);
  static final bodySemi = _s(14, FontWeight.w600, 20);
  static final body = _s(14, FontWeight.w400, 20);
  static final caption = _s(12, FontWeight.w500, 16, KColors.textSecondary);
  static final captionSemi = _s(12, FontWeight.w600, 16);
  static final small = _s(11, FontWeight.w600, 14, KColors.textSecondary);
  static final smallMedium = _s(11, FontWeight.w500, 14, KColors.textSecondary);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'PlusJakartaSans',
    scaffoldBackgroundColor: KColors.canvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: KColors.primary,
      primary: KColors.primary,
      surface: KColors.surface,
      error: KColors.danger,
    ),
    splashFactory: InkSparkle.splashFactory,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: KColors.text, displayColor: KColors.text, fontFamily: 'PlusJakartaSans'),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: KColors.text,
      contentTextStyle: KText.bodyMedium.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(KRadius.md)),
      actionTextColor: const Color(0xFF9FE0B5),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: KColors.canvas,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: Color(0xFFD5CFC2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(KRadius.lg))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: KColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(KRadius.lg)),
      titleTextStyle: KText.h18,
      contentTextStyle: KText.body.copyWith(color: KColors.textSecondary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: KText.bodyMedium.copyWith(color: KColors.textSecondary),
      labelStyle: KText.bodyMedium.copyWith(color: KColors.textSecondary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(KRadius.md), borderSide: const BorderSide(color: KColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(KRadius.md), borderSide: const BorderSide(color: KColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(KRadius.md), borderSide: const BorderSide(color: KColors.primary, width: 1.5)),
    ),
    sliderTheme: const SliderThemeData(activeTrackColor: KColors.primary, thumbColor: KColors.primary, inactiveTrackColor: KColors.subtle),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: KColors.text, borderRadius: BorderRadius.circular(8)),
      textStyle: KText.small.copyWith(color: Colors.white),
    ),
  );
}
