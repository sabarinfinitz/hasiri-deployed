import 'package:flutter/material.dart';

// Custom Color Palette - HASIRI AgriAssistant
// Color Ratio: White(60%) : Green(30%) : Yellow(10%)
class KissanColors {
  // Primary Colors
  static const Color primary = Color(0xFF1F8F4C);         // New Primary Green
  static const Color primaryDark = Color(0xFF1B7A42);     // Darker variant of new primary
  static const Color secondary = Color(0xFF2BA55D);       // Lighter variant of new primary
  
  // Paddy Crop Yellow Colors
  static const Color accent = Color(0xFFF9A825);          // Paddy Gold
  static const Color highlight = Color(0xFFFDD835);       // Bright Paddy Yellow
  static const Color grain = Color(0xFFFFE082);           // Light Grain Yellow
  
  // Background & Surface Colors (White dominant)
  static const Color background = Color(0xFFFAFAFA);      // Pure White Background
  static const Color surface = Color(0xFFFFFFFF);         // Card/Surface White
  static const Color surfaceVariant = Color(0xFFF1F8E9);  // Light Green Tint
  
  // Supporting Colors
  static const Color warning = Color(0xFFFF8F00);         // Amber Warning
  static const Color success = Color(0xFF4CAF50);         // Success Green
  static const Color textPrimary = Color(0xFF1B7A42);     // Dark variant of new primary for text
  static const Color textSecondary = Color(0xFF757575);   // Gray Text
  
  // Enhanced Gradient combinations
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1F8F4C), Color(0xFF2BA55D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF9A825), Color(0xFFFDD835)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFF8F00), Color(0xFFF9A825)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient freshGradient = LinearGradient(
    colors: [Color(0xFF2BA55D), Color(0xFFFFE082)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // White-Green blend gradient for backgrounds
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF1F8E9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
