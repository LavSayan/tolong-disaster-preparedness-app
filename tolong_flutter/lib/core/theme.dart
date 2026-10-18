import 'package:flutter/material.dart';

/// Text-bearing colours are tuned to meet WCAG AA (4.5:1) on the cream/canvas backgrounds and,
/// for [sage], with white text on top. The design's original sage (#63896D, ~3.9:1 with white)
/// was deepened slightly for that reason; the soft tints are unchanged.
class AppColors {
  static const ink = Color(0xFF24332D);
  static const muted = Color(0xFF5C6B63);
  static const line = Color(0xFFE6E3D9);
  static const sage = Color(0xFF52775D);
  static const sageSoft = Color(0xFFE4EEE3);
  static const blue = Color(0xFF4A7486);
  static const blueSoft = Color(0xFFE6EFF3);
  static const amber = Color(0xFFC9944F);
  static const amberSoft = Color(0xFFF5EAD6);
  static const terracotta = Color(0xFFBD7357);
  static const terracottaSoft = Color(0xFFF3E0D7);
  static const cream = Color(0xFFFBFAF6);
  static const canvas = Color(0xFFF8F6EF);
  static const outer = Color(0xFFE9EEE8);

  static const primary = sage;
  static const secondary = blue;
  static const background = canvas;
  static const surface = cream;
  static const success = Color(0xFF3F7A4C);

  /// Amber is decorative; this darker shade is for warning text and icons.
  static const warning = Color(0xFF8A5E1F);

  /// Secondary labels (dates, captions, hints) that still need to be readable.
  static const subtle = muted;
  static const error = Color(0xFF9E4330);
  static const errorSoft = terracottaSoft;
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}

class AppRadii {
  static const sm = 10.0;
  static const md = 12.0;
  static const tile = 16.0;
  static const card = 20.0;
  static const hero = 24.0;
  static const pill = 99.0;
}

class AppIconSizes {
  static const sm = 14.0;
  static const md = 18.0;
  static const lg = 21.0;
  static const xl = 24.0;
}

class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 450);
}

/// Returns [duration], or zero when the OS or the in-app setting asks for reduced motion.
Duration motion(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;

TextStyle sans(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.ink,
  double? height,
  double letterSpacing = 0,
}) =>
    TextStyle(
      fontFamily: 'DMSans',
      fontSize: size,
      fontWeight: weight,
      // Variable fonts need the weight axis set explicitly; fontWeight alone doesn't move it.
      fontVariations: [FontVariation.weight(weight.value.toDouble()), FontVariation.opticalSize(size.clamp(9, 40))],
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

TextStyle serif(
  double size, {
  Color color = AppColors.ink,
  double height = 1.1,
  double tracking = -0.04,
}) =>
    TextStyle(
      fontFamily: 'Fraunces',
      fontSize: size,
      fontWeight: FontWeight.w600,
      fontVariations: [const FontVariation.weight(600), FontVariation.opticalSize(size.clamp(9, 144))],
      color: color,
      height: height,
      letterSpacing: tracking * size,
    );

ThemeData buildAppTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'DMSans',
  );
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.md),
    borderSide: const BorderSide(color: AppColors.line),
  );
  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md));

  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: fieldBorder.copyWith(borderSide: const BorderSide(color: AppColors.error)),
      focusedErrorBorder: fieldBorder.copyWith(borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
      labelStyle: sans(13, color: AppColors.muted),
      floatingLabelStyle: sans(13, weight: FontWeight.w600, color: AppColors.primary),
      helperStyle: sans(11, color: AppColors.muted),
      errorStyle: sans(11, color: AppColors.error),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primary.withAlpha(110),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: buttonShape,
        textStyle: sans(13, weight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: AppColors.surface,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppColors.line),
        shape: buttonShape,
        textStyle: sans(13, weight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: sans(12, weight: FontWeight.w700),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: sans(12, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: const BorderSide(color: Color(0xFFCCD5CC), width: 1.5),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
      titleTextStyle: serif(20),
      contentTextStyle: sans(13, height: 1.45, color: AppColors.muted),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.hero))),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
  );
}
