import 'package:flutter/material.dart';

class AppColors {  
  // Primary Colors - Main teal theme
  static const Color primary = Color(0xFF002C2E);
  static const Color primaryDark = Color(0xFF001A1C);
  static const Color primaryLight = Color(0xFF2E5A5E);
  
  // Secondary Colors - for guide mode (slightly lighter teal)
  static const Color secondary = Color(0xFF2E5A5E);
  static const Color secondaryDark = Color(0xFF1B3A3C);
  static const Color secondaryLight = Color(0xFF7BB3B6);
  
  // Basic Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
  
  // Gray Scale - More neutral palette
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
  
  // Status Colors - Muted versions instead of bright colors
  static const Color success = Color(0xFF4A7C7A);        // Muted teal-green
  static const Color warning = Color(0xFF8B7355);        // Muted brown-orange
  static const Color error = Color(0xFF7A5555);          // Muted red-brown
  static const Color info = Color(0xFF556B7A);           // Muted blue-gray
  
  // Additional muted colors for specific use cases
  static const Color mutedGreen = Color(0xFF4A7C7A);     // Same as success
  static const Color mutedRed = Color(0xFF7A5555);       // Same as error
  static const Color mutedOrange = Color(0xFF8B7355);    // Same as warning
  static const Color grey = Color(0xFF9CAFB0);           // Same as gray500
  
  // Material Design 3 color scheme compatibility
  static const Color outline = Color(0xFFB8C6C7);        // Same as gray400
  static const Color onSurfaceVariant = Color(0xFF7A8E8F); // Same as textSecondary
  static const Color onSurface = Color(0xFF2D3738);      // Same as textPrimary
  
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
  static const Color rating = Color(0xFF8B7355);         
  static const Color favorite = Color(0xFF7A5555);       
  static const Color online = Color(0xFF4A7C7A);         
  static const Color offline = Color(0xFF9CAFB0);         
  
  // Tourism Colors
  static const Color tourist = Color(0xFF26A69A);        
  static const Color guide = Color(0xFF2E5A5E);          
  static const Color place = Color(0xFF7BB3B6);          
  static const Color tour = Color(0xFF4A8B8D);           
  
  // Map Colors
  static const Color mapMarker = Color(0xFF8B7355);      
  static const Color mapPath = Color(0xFF26A69A);        
  static const Color mapArea = Color(0x1A26A69A);        
  
  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF26A69A),  // Primary teal
    Color(0xFF2E5A5E),  // Dark teal
    Color(0xFF7BB3B6),  // Light teal
    Color(0xFF4A8B8D),  // Medium teal
    Color(0xFF1B3A3C),  // Very dark teal
    Color(0xFF5F7172),  // Gray-teal
  ];
  
  // Gradient Colors
  static const Gradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Gradient secondaryGradient = LinearGradient(
    colors: [secondaryLight, secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Color Opacity Methods
  static Color primaryWithOpacity(double opacity) => primary.withValues(alpha: opacity);
  static Color secondaryWithOpacity(double opacity) => secondary.withValues(alpha: opacity);
  static Color successWithOpacity(double opacity) => success.withValues(alpha: opacity);
  static Color warningWithOpacity(double opacity) => warning.withValues(alpha: opacity);
  static Color errorWithOpacity(double opacity) => error.withValues(alpha: opacity);
  static Color infoWithOpacity(double opacity) => info.withValues(alpha: opacity);
  
  // Overlay colors - muted
  static Color successOverlay() => successWithOpacity(0.1);
  static Color errorOverlay() => errorWithOpacity(0.1);
  static Color warningOverlay() => warningWithOpacity(0.1);
  static Color infoOverlay() => infoWithOpacity(0.1);
  
  // Additional overlay and surface methods for compatibility
  static Color surfaceOverlay() => gray100;
  static Color surfaceElevated() => white;
  static Color primarySubtle() => primaryWithOpacity(0.1);
  static Color secondarySubtle() => secondaryWithOpacity(0.1);
  static Color primaryMedium() => primaryWithOpacity(0.3);
  static Color primaryLightOverlay() => primaryLight.withValues(alpha: 0.1);
  static Color secondaryLightOverlay() => secondaryLight.withValues(alpha: 0.1);
  
  // Mode-dependent colors for shared screens
  static Color getModeColor(bool isGuideMode) {
    return isGuideMode ? secondary : primary;
  }
  
  static Color getModeDarkColor(bool isGuideMode) {
    return isGuideMode ? secondaryDark : primaryDark;
  }
  
  static Color getModeLightColor(bool isGuideMode) {
    return isGuideMode ? secondaryLight : primaryLight;
  }
  
  static Color getModeColorWithOpacity(bool isGuideMode, double opacity) {
    return getModeColor(isGuideMode).withValues(alpha: opacity);
  }
  
  static Gradient getModeGradient(bool isGuideMode) {
    return isGuideMode ? secondaryGradient : primaryGradient;
  }
  
  // Status colors with consistent theme
  static const Color statusDraft = gray500;
  static const Color statusPublished = success;
  static const Color statusArchived = gray400;
  
  // Action colors consistent with theme - all muted
  static const Color actionEdit = info;
  static const Color actionDelete = error;
  static const Color actionSave = warning;
  static const Color actionPublish = success;
  
  // Background variations
  static const Color backgroundLight = gray50;
  static const Color surfaceVariant = gray100;
  static const Color cardElevated = white;
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