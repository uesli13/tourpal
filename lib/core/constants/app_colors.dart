import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF002C2E);
  static const Color primaryDark = Color(0xFF001A1C);
  static const Color primaryLight = Color(0xFF2E5A5E);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF4A8B8D);
  static const Color secondaryDark = Color(0xFF2E5A5E);
  static const Color secondaryLight = Color(0xFF7BB3B6);
  
  // Accent Colors
  static const Color accent = Color(0xFFE8A87C);
  static const Color accentDark = Color(0xFFD4926A);
  static const Color accentLight = Color(0xFFF2C9A8);
  
  // Basic Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
  
  // Gray Scale
  static const Color gray50 = Color(0xFFF8FAFA);
  static const Color gray100 = Color(0xFFF0F4F4);
  static const Color gray200 = Color(0xFFE6EEEE);
  static const Color gray300 = Color(0xFFD1DCDC);
  static const Color gray400 = Color(0xFFB8C6C7);
  static const Color gray500 = Color(0xFF9CAFB0);
  static const Color gray600 = Color(0xFF7A8E8F);
  static const Color gray700 = Color(0xFF5F7172);
  static const Color gray800 = Color(0xFF455354);
  static const Color gray900 = Color(0xFF2D3738);
  
  // Status Colors
  static const Color success = Color(0xFF4A8B8D);
  static const Color warning = Color(0xFFE8A87C);
  static const Color error = Color(0xFFD4646A);
  static const Color info = Color(0xFF6BA3A6);
  
  // Background Colors
  static const Color background = Color(0xFFF8FAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF2D3738);
  static const Color textSecondary = Color(0xFF7A8E8F);
  static const Color textHint = Color(0xFFB8C6C7);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);
  
  // Divider Colors
  static const Color divider = Color(0xFFE6EEEE);
  static const Color border = Color(0xFFE6EEEE);
  
  // Shadow Colors
  static const Color shadow = Color(0x1F002C2E);
  static const Color shadowLight = Color(0x0A002C2E);
  static const Color shadowDark = Color(0x3D002C2E);
  
  // Special Colors
  static const Color rating = Color(0xFFE8A87C);
  static const Color favorite = Color(0xFFD4646A);
  static const Color online = Color(0xFF4A8B8D);
  static const Color offline = Color(0xFF9CAFB0);
  
  // Social Colors
  static const Color google = Color(0xFFDB4437);
  static const Color facebook = Color(0xFF3B5998);
  static const Color twitter = Color(0xFF1DA1F2);
  
  // Tourism Colors
  static const Color tourist = Color(0xFF6BA3A6);
  static const Color guide = Color(0xFF4A8B8D);
  static const Color place = Color(0xFF7A8E8F);
  static const Color tour = Color(0xFF2E5A5E);
  
  // Map Colors
  static const Color mapMarker = Color(0xFFE8A87C);
  static const Color mapPath = Color(0xFF4A8B8D);
  static const Color mapArea = Color(0x1A4A8B8D);
  
  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF002C2E),
    Color(0xFF4A8B8D),
    Color(0xFFE8A87C),
    Color(0xFF7BB3B6),
    Color(0xFF2E5A5E),
    Color(0xFFD4926A),
  ];
  
  // Gradient Colors
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Gradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Gradient accentGradient = LinearGradient(
    colors: [accent, accentDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Color Opacity Methods
  static Color primaryWithOpacity(double opacity) => primary.withValues(alpha: opacity);
  static Color secondaryWithOpacity(double opacity) => secondary.withValues(alpha: opacity);
  static Color accentWithOpacity(double opacity) => accent.withValues(alpha: opacity);
  static Color blackWithOpacity(double opacity) => black.withValues(alpha: opacity);
  static Color whiteWithOpacity(double opacity) => white.withValues(alpha: opacity);
  
  // Material Color Swatch
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF002C2E,
    <int, Color>{
      50: Color(0xFFF8FAFA),
      100: Color(0xFFE6F1F2),
      200: Color(0xFFCCE3E5),
      300: Color(0xFFB3D4D7),
      400: Color(0xFF80B7BC),
      500: Color(0xFF4A8B8D),
      600: Color(0xFF2E5A5E),
      700: Color(0xFF1A3A3D),
      800: Color(0xFF0D2729),
      900: Color(0xFF002C2E),
    },
  );
}

// Color Utilities Extension
extension AppColorsExtension on Color {
  Color get darker {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
  }
  
  Color get lighter {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness + 0.1).clamp(0.0, 1.0)).toColor();
  }
  
  Color get contrastingTextColor {
    final brightness = ThemeData.estimateBrightnessForColor(this);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }
}
