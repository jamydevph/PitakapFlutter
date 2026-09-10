import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0E7A5F);
  static const Color primaryDark = Color(0xFF0A5C48);
  static const Color mint = Color(0xFFD1F0E5);

  static const Color background = Color(0xFFF5F7F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color field = Color(0xFFF4F6F5);
  static const Color border = Color(0xFFEAECF0);

  static const Color ink = Color(0xFF101828);
  static const Color inkSub = Color(0xFF667085);

  static const Color onPrimary = Color(0xFFD1F0E5);
  static const Color onPrimarySub = Color(0xFFA7DECD);
  static const Color onMint = Color(0xFF0A5C48);
  static const Color onMintSub = Color(0xFF0E7A5F);

  static const Color danger = Color(0xFFE5484D);
  static const Color dangerText = Color(0xFFB42318);
  static const Color divider = Color(0xFFEAECF0);

  static const Color darkPrimary = Color(0xFF35C79A);
  static const Color darkOnPrimary = Color(0xFF00382A);
  static const Color darkMint = Color(0xFF0A5C48);

  static const Color darkBackground = Color(0xFF0B1017);
  static const Color darkSurface = Color(0xFF131A23);
  static const Color darkField = Color(0xFF161D26);
  static const Color darkBorder = Color(0xFF606E82);
  static const Color darkDivider = Color(0xFF2A3441);

  static const Color darkInk = Color(0xFFE7EBF0);
  static const Color darkInkSub = Color(0xFF98A2B3);

  static const Color darkDanger = Color(0xFFFF6B6E);
  static const Color darkOnDanger = Color(0xFF2B0708);
  static const Color darkDangerText = Color(0xFFFF6B6E);

  static const Color categoryFood = Color(0xFFF97316);
  static const Color categoryTransport = Color(0xFF3B82F6);
  static const Color categoryGroceries = Color(0xFF16A34A);
  static const Color categoryShopping = Color(0xFFEC4899);

  static const Map<String, Color> categoryAccents = {
    'food': categoryFood,
    'transport': categoryTransport,
    'groceries': categoryGroceries,
    'shopping': categoryShopping,
    'entertainment': Color(0xFFE5484D),
    'utilities': Color(0xFFFFB020),
    'health': Color(0xFF06B6D4),
    'productivity': Color(0xFF14B8A6),
    'education': Color(0xFF0E7A5F),
    'bills': Color(0xFF8B5CF6),
    'other': Color(0xFF667085),
  };

  static Color categoryAccent(String category) =>
      categoryAccents[category] ?? inkSub;

  static const List<Color> subscriptionPalette = [
    Color(0xFFE5484D),
    Color(0xFF0E7A5F),
    Color(0xFF3B82F6),
    Color(0xFFF97316),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF667085),
  ];
}

class AppRadius {
  AppRadius._();

  static const double field = 14;
  static const double button = 14;
  static const double card = 18;
  static const double tile = 12;
  static const double sheet = 24;
  static const double pill = 999;
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppTheme {
  AppTheme._();

  static const String _fontFamily = 'Inter';

  static ThemeData light() => _build(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.mint,
        onPrimaryContainer: AppColors.primaryDark,
        background: AppColors.background,
        surface: AppColors.surface,
        fieldFill: AppColors.field,
        border: AppColors.border,
        divider: AppColors.divider,
        ink: AppColors.ink,
        inkSub: AppColors.inkSub,
        danger: AppColors.danger,
        onDanger: Colors.white,
        dangerText: AppColors.dangerText,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        primaryContainer: AppColors.darkMint,
        onPrimaryContainer: AppColors.mint,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        fieldFill: AppColors.darkField,
        border: AppColors.darkBorder,
        divider: AppColors.darkDivider,
        ink: AppColors.darkInk,
        inkSub: AppColors.darkInkSub,
        danger: AppColors.darkDanger,
        onDanger: AppColors.darkOnDanger,
        dangerText: AppColors.darkDangerText,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color onPrimary,
    required Color primaryContainer,
    required Color onPrimaryContainer,
    required Color background,
    required Color surface,
    required Color fieldFill,
    required Color border,
    required Color divider,
    required Color ink,
    required Color inkSub,
    required Color danger,
    required Color onDanger,
    required Color dangerText,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: primary,
      onSecondary: onPrimary,
      surface: surface,
      onSurface: ink,
      surfaceContainerLowest: background,
      surfaceContainerHighest: fieldFill,
      onSurfaceVariant: inkSub,
      outline: border,
      outlineVariant: border,
      error: danger,
      onError: onDanger,
    );

    TextStyle style(
      double size,
      FontWeight weight, {
      Color? color,
      double? height,
      double letterSpacing = 0,
    }) =>
        TextStyle(
          fontFamily: _fontFamily,
          fontSize: size,
          fontWeight: weight,
          color: color ?? ink,
          height: height,
          letterSpacing: letterSpacing,
        );

    final textTheme = TextTheme(
      displayLarge: style(40, FontWeight.w700, letterSpacing: -0.5),
      displayMedium: style(36, FontWeight.w700, letterSpacing: -0.5),
      displaySmall: style(34, FontWeight.w700, letterSpacing: -0.5),
      headlineLarge: style(28, FontWeight.w700),
      headlineMedium: style(24, FontWeight.w700),
      headlineSmall: style(22, FontWeight.w700),
      titleLarge: style(18, FontWeight.w600),
      titleMedium: style(16, FontWeight.w600),
      titleSmall: style(15, FontWeight.w600),
      bodyLarge: style(15, FontWeight.w500, height: 1.5),
      bodyMedium: style(14, FontWeight.w400, color: inkSub, height: 1.5),
      bodySmall: style(13, FontWeight.w400, color: inkSub),
      labelLarge: style(15, FontWeight.w600),
      labelMedium: style(13, FontWeight.w500, color: inkSub),
      labelSmall: style(11, FontWeight.w400, color: inkSub),
    );

    OutlineInputBorder inputBorder(Color color, double width) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: color, width: width),
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: background,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: style(18, FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle: style(15, FontWeight.w400, color: inkSub),
        labelStyle: style(13, FontWeight.w500, color: inkSub),
        floatingLabelStyle: style(13, FontWeight.w500, color: primary),
        errorStyle: style(13, FontWeight.w400, color: dangerText),
        enabledBorder: inputBorder(border, 1.5),
        focusedBorder: inputBorder(primary, 1.8),
        errorBorder: inputBorder(danger, 1.5),
        focusedErrorBorder: inputBorder(danger, 1.8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: style(16, FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: style(16, FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: style(14, FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary,
        side: BorderSide(color: border),
        labelStyle: style(13, FontWeight.w500).copyWith(
          color: WidgetStateColor.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? onPrimary : ink,
          ),
        ),
        secondaryLabelStyle: style(13, FontWeight.w500, color: onPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: const StadiumBorder(),
      ),
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 2,
        shape: const CircleBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        height: 68,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? style(11, FontWeight.w600, color: primary)
              : style(11, FontWeight.w400, color: inkSub),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected) ? primary : inkSub,
          ),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        width: 300,
        shape: const RoundedRectangleBorder(),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? style(15, FontWeight.w600, color: onPrimaryContainer)
              : style(15, FontWeight.w500, color: ink),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? onPrimaryContainer
                : ink,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: style(14, FontWeight.w500, color: surface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
        titleTextStyle: style(18, FontWeight.w600),
        contentTextStyle: style(14, FontWeight.w400, color: inkSub),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: inkSub,
        titleTextStyle: style(15, FontWeight.w500),
        subtitleTextStyle: style(13, FontWeight.w400, color: inkSub),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
      ),
      iconTheme: IconThemeData(color: ink, size: 24),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
    );
  }
}
